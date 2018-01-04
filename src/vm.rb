# frozen_string_literal: true

require 'config'
require 'libvirt'
require 'metal_log'
require 'namespaces/alces'

module Metalware
  class Vm
    def initialize(libvirt_host, node, *args)
      @libvirt ||= Libvirt.open("qemu://#{libvirt_host}/system")
      @node = node
      @args = args
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
        puts "#{@node}: Power state: #{state}"
      else
        raise MetalwareError, "Invalid command: #{cmd}"
      end
    end

    def console
      puts "Attempting to connect to node #{@node}"
      domain.open_console if running?
    end

    def create
      puts "Provisioning new storage volume for #{@node}"
      storage.create_volume_xml(render_template('disk'))
      puts "Provisioning new machine #{@node}"
      @libvirt.define_domain_xml(render_template('vm'))
    end

    def destroy
      domain.destroy if running?
      puts "Removing domain #{@node}"
      domain.undefine
      vol = storage.lookup_volume_by_name(@node)
      puts "Removing #{@node} storage volume"
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

    def render_template(type)
      path = "/var/lib/metalware/repo/libvirt/#{type}.xml"
      node = alces.nodes.find_by_name(@node)
      templater = node ? node : alces
      templater.render_erb_template(File.read(path))
    end
  end
end
