
# frozen_string_literal: true

require 'network_interface'

module Metalware
  module Network
    class << self
      delegate :interfaces, to: NetworkInterface
    end
  end
end
