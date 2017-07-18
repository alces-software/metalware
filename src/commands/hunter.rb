# frozen_string_literal: true

#==============================================================================
# Copyright (C) 2017 Stephen F. Norledge and Alces Software Ltd.
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

require 'command_helpers/base_command'
require 'metal_log'
require 'net/dhcp'
require 'pcap'

require 'templater'
require 'output'
require 'constants'
# require 'alces/stack/log'
require 'hunter_updater'

module Metalware
  module Commands
    class Hunter < CommandHelpers::BaseCommand
      private

      def setup(_args, options)
        @hunter_log = MetalLog.new('hunter')

        @options = options

        @detection_count = options.start
        @detected_macs = []

        setup_network_connection
      end

      def run
        listen!
      end

      def listen!
        Output.stderr \
          'Waiting for new nodes to appear on the network, please network ' \
          'boot them now...',
          '(Ctrl-C to terminate)'

        @network.each_packet do |packet|
          process_packet(packet.udp_data) if packet.udp?
        end
      end

      def setup_network_connection
        pcaplet_options = "-s 600 -n -i #{@options.interface}"
        @network ||= Pcaplet.new(pcaplet_options).tap do |network|
          filter_string = 'udp port 67 and udp port 68'
          filter = Pcap::Filter.new(filter_string, network.capture)
          network.add_filter(filter)
        end
      end

      def process_packet(data)
        @hunter_log.info 'Processing received UDP packet'
        message = DHCP::Message.from_udp_payload(data, debug: false)
        process_message(message) if message.is_a?(DHCP::Discover)
      end

      def process_message(message)
        @hunter_log.info 'Processing DHCP::Discover message options'
        message.options.each do |o|
          detected(hwaddr_from(message)) if pxe_client?(o)
        end
      end

      def hwaddr_from(message)
        @hunter_log.info 'Determining hardware address'
        message.chaddr.slice(0..(message.hlen - 1)).map do |b|
          b.to_s(16).upcase.rjust(2, '0')
        end.join(':').tap do |hwaddr|
          @hunter_log.info "Detected hardware address: #{hwaddr}"
        end
      end

      def pxe_client?(o)
        o.is_a?(DHCP::VendorClassIDOption) && o.payload.pack('C*').tap do |vendor|
          @hunter_log.info "Detected vendor: #{vendor}"
        end =~ /^PXEClient/
      end

      def detected(hwaddr)
        return if @detected_macs.include?(hwaddr)
        default_name = sequenced_name

        @detected_macs << hwaddr
        @detection_count += 1

        begin
          name_node_question = \
            "Detected a machine on the network (#{hwaddr}). Please enter " \
            'the hostname:'
          name = ask(name_node_question) do |answer|
            answer.default = default_name
          end
          record_hunted_pair(name, hwaddr)
          MetalLog.info "#{name}-#{hwaddr}"
          @hunter_log.info "#{name}-#{hwaddr}"
          Output.stderr 'Logged node'
        rescue => e
          warn e # XXX Needed?
          Output.stderr "FAIL: #{e.message}"
          retry if agree('Retry? [yes/no]:')
        end
      end

      def record_hunted_pair(node_name, mac_address)
        hunter_updater.add(node_name, mac_address)
      end

      def hunter_updater
        @hunter_updater ||= HunterUpdater.new(Constants::HUNTER_PATH)
      end

      def sequenced_name
        "#{@options.prefix}#{@detection_count.to_s.rjust(@options.length, '0')}"
      end

      def handle_interrupt(_e)
        Output.stderr 'Exiting...'
        exit
      end
    end
  end
end
