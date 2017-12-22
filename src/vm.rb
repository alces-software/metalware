# frozen_string_literal: true

require 'config'
require 'libvirt'
require 'metal_log'

module Metalware
  class Vm
    attr_accessor :node

    def initialize(libvirt_host, node, *args)
      @libvirt ||= Libvirt.open("qemu://#{libvirt_host}/system")
      @storage ||= @libvirt.lookup_storage_pool_by_name(args[0]) if args[0]
      @node = node
    end

    def info
      { state: state }
    end

    def run(cmd)
      case cmd
      when 'kill'
        puts "Killing node #{@node}.."
        domain.destroy if running?
      when 'on'
        puts "Powering up node #{@node}.."
        domain.create unless running?
      when 'off'
        puts "Powering down node #{@node}.."
        domain.shutdown if running?
      when 'reboot'
        puts "Rebooting node #{@node}.."
        domain.reboot if running?
      when 'status'
        puts "#{@node}: Power state: #{info[:state]}"
      else
        raise 'Not possible'
      end
    end

    def console
      puts "Attempting to connect to node #{@node}"
      domain.open_console if running?
    end

    def create(storage, vm)
      puts "Provisioning new disk for #{@node}"
      @storage.create_volume_xml(storage)
      puts "Provisioning new machine #{@node}"
      @libvirt.define_domain_xml(vm)
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

    def stream
      @libvirt.stream
    end
  end
end
