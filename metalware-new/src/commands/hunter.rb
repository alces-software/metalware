
require 'net/dhcp'
require 'pcap'

require 'templater'
require 'output'
# require 'alces/stack/log'


module Metalware
  module Commands
    class Hunter
      def initialize(_args, options)
        setup(options)
        listen!
      rescue Interrupt
        handle_interrupt
      end

      private

      def setup(options)
        # XXX Always default interface to Metalware build interface (where
        # possible)?
        # XXX setup Pcaplet here so fails fast if this fails
        options.default \
          interface: 'eth0',
          prefix: 'node',
          length: 2,
          start: 1
        @options = options

        @detection_count = options.start
        @update_dhcp_flag = true # XXX Remove when remove dhcp updating
        @templateFilename = File.join(Constants::REPO_PATH, 'dhcp', 'default') # XXX Also to remove
        @detected_macs = []
        # @hunter_logger = Alces::Stack::Log.create_log("/var/log/metalware/hunter.log")
      end

      def listen!
        Output.stderr \
          'Waiting for new nodes to appear on the network, please network boot them now...',
          '(Ctrl-C to terminate)'

        network.each do |p|
          process_packet(p.udp_data) if p.udp?
        end
      end

      def network
        @network ||= Pcaplet.new("-s 600 -n -i #{@options.interface}").tap do |network|
          filter = Pcap::Filter.new('udp port 67 and udp port 68', network.capture)
          network.add_filter(filter)
        end
      # rescue
        # Alces::Stack::Log.fatal "Failed to connect to network, check interface"
      end

      def process_packet(data)
        # @hunter_logger.info "Processing received UDP packet"
        message = DHCP::Message.from_udp_payload(data, :debug => false)
        process_message(message) if message.is_a?(DHCP::Discover)
      end

      def process_message(message)
        # @hunter_logger.info("Processing DHCP::Discover message options"){ message.options }
        message.options.each do |o|
          detected(hwaddr_from(message)) if pxe_client?(o)
        end
      end

      def hwaddr_from(message)
        # @hunter_logger.info "Determining hardware address"
        message.chaddr.slice(0..(message.hlen - 1)).map do |b|
          b.to_s(16).upcase.rjust(2,'0')
        end.join(':').tap do |hwaddr|
          # @hunter_logger.info "Detected hardware address: #{hwaddr}"
        end
      end

      def pxe_client?(o)
        o.is_a?(DHCP::VendorClassIDOption) && o.payload.pack('C*').tap do |vendor|
          # @hunter_logger.info "Detected vendor: #{vendor}"
        end =~ /^PXEClient/
      end

      def detected(hwaddr)
        return if @detected_macs.include?(hwaddr)
        default_name = sequenced_name

        @detected_macs << hwaddr
        @detection_count += 1

        begin
          name_node_question = "Detected a machine on the network (#{hwaddr}). Please enter the hostname:"
          name = ask(name_node_question) do |answer|
            answer.default = default_name
          end
          update_dhcp(name, hwaddr) if @update_dhcp_flag
          # Alces::Stack::Log.info("#{name}-#{hwaddr}")
          # @hunter_logger.info("#{name}-#{hwaddr}")
          Output.stderr 'Logged node'

        rescue Exception => e
          warn e # XXX Needed?
          Output.stderr "FAIL: #{e.message}"
          retry if agree('Retry? [yes/no]:')
        end
      end

      def update_dhcp(name, hwaddr)
        @DHCP_filename = "/etc/dhcp/dhcpd.hosts"
        fixedip = `gethostip -d #{name}`.chomp
        raise "Unable to resolve IP for host: #{name}" if fixedip.to_s.empty?
        remove_dhcp_entry(hwaddr)
        add_dhcp_entry(name, hwaddr, fixedip)
      end

      def add_dhcp_entry(name, hwaddr, fixedip)
        #Finds the host machine ip address
        template_parameters = {
          nodename: name.chomp,
          hwaddr: hwaddr.chomp,
          fixedaddr: fixedip.chomp
        }
        Templater::Combiner.new(template_parameters)
          .append(@templateFilename, @DHCP_filename)
      end

      def remove_dhcp_entry(hwaddr)
        tempFilename = "/tmp/dhcpd.hosts." << Process.pid.to_s

        # Checks if the mac address already exists in the list
        start_line = -1
        end_line = -1
        found = false
        File.open(@DHCP_filename) do |file|
          bracket_count = 0
          file.each_line.with_index do |line, index|
            raise "Can not alter dhcpd.hosts if multiple \'{\' or \'}\' are on the same line" if line.scan(/\{|\}/).count > 1
            start_line = index if !found and bracket_count == 0 and line.include? "{"
            bracket_count += 1 if line.include? "{"
            found = true if line.include? "#{hwaddr}"
            bracket_count -= 1 if line.include? "}"
            if found and bracket_count == 0 and line.include? "}"
              end_line = index
              break
            end
          end
          return unless found
          raise "Could not remove mac address from dhcpd.hosts" if start_line < 0 or end_line < 0
        end

        # Alces::Stack::Log.info "Removing old DHCP entry for: #{hwaddr}"
        # Creates the new file with the address removed
        File.open(tempFilename, "w", 0644) do |tempFile|
          File.open(@DHCP_filename) do |file|
            file.each_line.with_index do |line, index|
              tempFile.puts line if index < start_line or index > end_line
            end
          end
        end

        # Replaces the original file with the new one
        `mv -f #{tempFilename} #{@DHCP_filename}`
        `rm -f #{tempFilename}`
      end

      def sequenced_name
        "#{@options.prefix}#{@detection_count.to_s.rjust(@options.length, '0')}"
      end

      def handle_interrupt
        Output.stderr 'Exiting...'
        exit
      end
    end
  end
end
