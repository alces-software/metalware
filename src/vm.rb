# frozen_string_literal: true

require 'libvirt'
require 'metal_log'
require 'namespaces/alces'
require 'vm/certificate'

module Metalware
  class Vm
    attr_reader :node

    def initialize(node)
      @node = node
      certs = Certificate.new(node)
      certs.generate && return unless certs.exist?
    end

    def kill
      puts "Killing node #{node.name}.."
      domain.destroy if running?
    end

    def on
      puts "Powering up node #{node.name}.."
      domain.create unless running?
    end

    def off
      puts "Powering down node #{node.name}.."
      domain.shutdown if running?
    end

    def reboot
      puts "Rebooting node #{node.name}.."
      domain.reboot if running?
    end

    def status
      puts "#{node.name}: Power state: #{state}"
    end

    def console
      puts "Attempting to connect to node #{node.name}"
      domain.open_console if running?
    end

    def create
      puts "Provisioning new storage volume for #{node.name}"
      storage.create_volume_xml(render_template('disk'))
      puts "Provisioning new machine #{node.name}"
      @libvirt.define_domain_xml(render_template('vm'))
    end

    def destroy
      kill
      puts "Removing domain #{node.name}"
      domain.undefine
      vol = storage.lookup_volume_by_name(node.name)
      puts "Removing #{node.name} storage volume"
      vol.delete
    end

    private

    def libvirt_host
      node.config.libvirt_host
    end

    def libvirt
      @libvirt ||= Libvirt.open("qemu://#{libvirt_host}/system")
    end

    def domain
      libvirt.lookup_domain_by_name(node.name)
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
      else
        raise MetalwareError, "Unknown state: #{domain.info.state}"
      end
    end

    def storage
      @storage ||= libvirt.lookup_storage_pool_by_name(node.config.vm_disk_pool)
    end

    def render_template(type)
      path = "/var/lib/metalware/repo/libvirt/#{type}.xml"
      node.render_erb_template(File.read(path))
    end
  end
end
