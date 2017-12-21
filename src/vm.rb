# frozen_string_literal: true

require 'config'
require 'libvirt'

module Metalware
  class Vm
    attr_accessor :node

    def initialize(libvirt_host, node)
      @libvirt ||= Libvirt.open("qemu://#{libvirt_host}/system")
      @node = node
    end

    def info
      { state: state }
    end

    def run(cmd)
      case cmd
      when 'on'
        puts "Powering up node #{@node}.."
        start
      when 'off'
        puts "Powering down node #{@node}.."
        stop
      when 'status'
        puts "#{@node}: Power state: #{info[:state]}"
      else
        raise 'Not possible'
      end
    end

    def start
      domain.create unless running?
    end

    def stop
      domain.shutdown if running?
    end

    private

    def domain
     @libvirt.lookup_domain_by_name(@node)
    end

    def exists?
      @libvirt.lookup_domain_by_name(@node)
    end

    def running?
      domain.active?
    end

    def state
      case domain.info.state
        when 5
          'off'
        when 1
          'on'
      end
    end
  end
end
