
# frozen_string_literal: true

require 'network_interface'

module Metalware
  module Network
    class << self
      delegate :interfaces, to: NetworkInterface

      def valid_interface?(interface_name)
        NetworkInterface.interfaces.include?(interface_name)
      end
    end
  end
end
