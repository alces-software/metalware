# frozen_string_literal: true

require 'config'
require 'libvirt'
require 'metal_log'

module Metalware
  class Vm
    attr_accessor :node

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

    # Creates a new VM
    # - storage: Rendered Libvirt storage XML, used to create the root disk
    # - vm: Rendered Libvirt domain XML, used to create the domain
    def create(disk_tpl, domain_tpl)
      unless volume_exists?
        puts "Provisioning new storage volume for #{@node}"
        storage.create_volume_xml(disk_tpl)
      end
      unless domain_exists?
        puts "Provisioning new machine #{@node}"
        @libvirt.define_domain_xml(domain_tpl)
      end
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

    def domain_exists?
      @libvirt.lookup_domain_by_name(@node)
    end

    def volume_exists?
      storage.lookup_volume_by_name(@node)
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

    def storage
      @storage ||= @libvirt.lookup_storage_pool_by_name(@args[0])
    end
  end
end
