#==============================================================================
# Copyright (C) 2007-2015 Stephen F. Norledge and Alces Software Ltd.
#
# This file/package is part of Alces Metalware.
#
# Alces Metalware is free software: you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License
# as published by the Free Software Foundation, either version 3 of
# the License, or (at your option) any later version.
#
# Alces Metalware is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this package.  If not, see <http://www.gnu.org/licenses/>.
#
# For more information on the Alces Metalware, please visit:
# https://github.com/alces-software/metalware
#==============================================================================
require 'alces/tools/logging'
require 'alces/tools/execution'
require 'net/dhcp'
require 'pcaplet'

module Alces
  module Stack
    module Hunter
      class Listener
        include Alces::Tools::Logging
        include Alces::Tools::Execution

        def initialize(interface_name,options={})
          @interface_name=interface_name
          @detection_count=options[:name_sequence_start].to_i || 0
          @default_name_index_size=options[:name_sequence_length].to_i || 2
          @default_name=options[:name] || "node"
          @update_dhcp_flag=options[:update_dhcp_flag]
          @templateFilename=options[:template]
          @detected_macs=[]
          @logFilename = '/var/log/metalware/hunter.log'
          @logFile = File.open(@logFilename, "a")
          @logFile.sync = true
        end

        def listen!
          STDERR.puts "WAITING FOR NEW NODES TO APPEAR ON THE NETWORK, PLEASE NETWORK BOOT THEM NOW... (CTRL+C TO TERMINATE)"
          Thread.new do
            network.each do |p|
              process_packet(p.udp_data) if p.udp?
            end
          end
          sleep
        end

        private

        def network
          @network ||= begin
            Pcaplet.new("-s 600 -n -i #{@interface_name}").tap do |network|
              filter = Pcap::Filter.new('udp port 67 and udp port 68', network.capture)
              network.add_filter(filter)
            end
          end
        end

        def process_packet(data)
          info "Processing received UDP packet"
          message = DHCP::Message.from_udp_payload(data, :debug => false)
          process_message(message) if message.is_a?(DHCP::Discover)
        end

        def process_message(message)
          info("Processing DHCP::Discover message options"){ message.options }
          message.options.each do |o|
            detected(hwaddr_from(message)) if pxe_client?(o)
          end
        end

        def hwaddr_from(message)
          info "Determining hardware address"
          message.chaddr.slice(0..(message.hlen - 1)).map do |b|
            b.to_s(16).upcase.rjust(2,'0')
          end.join(':').tap do |hwaddr|
            info "Detected hardware address: #{hwaddr}"
          end
        end

        def pxe_client?(o)
          o.is_a?(DHCP::VendorClassIDOption) && o.payload.pack('C*').tap do |vendor|
            info "Detected vendor: #{vendor}"
          end =~ /^PXEClient/
        end

        def detected(hwaddr)
          return if @detected_macs.include?(hwaddr)
          default_name = sequenced_name

          @detected_macs << hwaddr
          @detection_count += 1

          begin
            STDERR.print "Detected a machine on the network (#{hwaddr}). Please enter the hostname [#{default_name}]: "
            STDERR.flush
            input = gets.chomp
            name = input.empty? ? default_name : input
            update_dhcp(name, hwaddr) if @update_dhcp_flag
            log_address(name, hwaddr)

          rescue Exception => e
            warn e
            STDERR.puts "FAIL: #{e.message}"; STDERR.flush
            STDERR.print "Retry? (Y/N): "; STDERR.flush
            input=gets.chomp
            retry if input.to_s.downcase == 'y'
          end
        end

        def log_address(name, hwaddr)
          @logFile.puts("#{name}-#{hwaddr}")
          STDERR.puts "Logged in: #{@logFilename}"
        end

        def update_dhcp(name, hwaddr)
          @DHCP_filename = "/etc/dhcp/dhcpd.hosts"
          fixedip=`gethostip -d #{name}`.chomp
          raise "Unable to resolve IP for host:#{name}" if fixedip.to_s.empty?
          remove_dhcp_entry(hwaddr)
          add_dhcp_entry(name, hwaddr, fixedip)
        end

        def add_dhcp_entry(name, hwaddr, fixedip)
          #Finds the host machine ip address
          hostip = `ifconfig | grep -A1 #{@interface_name} | grep inet | tr -ds "[:alpha:]" ' ' | cut -d' ' -f2`
          hostip.gsub!("\n", "")

          File.open(@templateFilename, 'r') do |templateF|
            content = templateF.read
            content.gsub!(/%NODENAME%/, name)
            content.gsub!(/%HWADDR%/, hwaddr)
            content.gsub!(/%HOSTIP%/, hostip)
            content.gsub!(/%FIXEDADDR%/, fixedip)
            File.open(@DHCP_filename, 'a') do |file|
              file.puts content
            end
          end
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
              bracket_count+=1 if line.include? "{"
              found = true if line.include? "#{hwaddr}"
              bracket_count-=1 if line.include? "}"
              if found and bracket_count == 0 and line.include? "}"
                end_line = index
                break
              end
            end
            return if !found
            raise "Could not remove mac address from dhcpd.hosts" if start_line < 0 or end_line < 0
          end

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
          "#{@default_name}#{@detection_count.to_s.rjust(@default_name_index_size,'0')}"
        end
      end
    end
  end
end
