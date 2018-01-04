# frozen_string_literal: true

require 'config'
require 'libvirt'
require 'metal_log'

module Metalware
  class Vm
    def initialize(libvirt_host, node, *args)
      @libvirt ||= Libvirt.open("qemu://#{libvirt_host}/system")
      @node = node
      @args = args
    end

    def info
      { state: state }
    end

    def run(cmd)
      case cmd
      when 'kill'
        puts "Killing node #{@node}.."
        domain.destroy
      when 'on'
        puts "Powering up node #{@node}.."
        domain.create
      when 'off'
        puts "Powering down node #{@node}.."
        domain.shutdown
      when 'reboot'
        puts "Rebooting node #{@node}.."
        domain.reboot
      when 'status'
        puts "#{@node}: Power state: #{info[:state]}"
      else
        raise MetalwareError, "Invalid command: #{cmd}"
      end
    end

    def console
      puts "Attempting to connect to node #{@node}"
      domain.open_console if running?
    end

    # Creates a new VM
    # - storage: Rendered Libvirt storage XML, used to create the root disk
    # - vm: Rendered Libvirt domain XML, used to create the domain
    def create(disk_tpl, domain_tpl)
      puts "Provisioning new storage volume for #{@node}"
      storage.create_volume_xml(disk_tpl)
      puts "Provisioning new machine #{@node}"
      @libvirt.define_domain_xml(domain_tpl)
    end

    # Destroys a VM and its associated disk
    # - domain: Domain name
    def destroy(node_name)
      domain.destroy if running?
      puts "Removing domain #{node_name}"
      domain.undefine
      vol = storage.lookup_volume_by_name(node_name)
      puts "Removing #{node_name} storage volume"
      vol.delete
    end

    private

    def domain
      @libvirt.lookup_domain_by_name(@node)
    end

    def running?
      domain.active?
    end

    def state
      case domain.info.state
      when 0
        'no state'
      when 1
        'on'
      when 2
        'blocked'
      when 3
        'paused'
      when 4
        'shutting down'
      when 5
        'off'
      when 6
        'crashed'
      when 7
        'suspended'
      end
    end

    def stream
      @libvirt.stream
    end

    def storage
      @storage ||= @libvirt.lookup_storage_pool_by_name(@args[0])
    end
  end
end
