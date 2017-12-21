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
      when 'kill'
        puts "Killing node #{@node}.."
        kill
      when 'on'
        puts "Powering up node #{@node}.."
        start
      when 'off'
        puts "Powering down node #{@node}.."
        stop
      when 'reboot'
        puts "Rebooting node #{@node}.."
        reboot
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

    def kill
      domain.destroy if running?
    end

    def reboot
      domain.reboot if running?
    end

    def start
      domain.create unless running?
    end

    def stop
      domain.shutdown if running?
    end

    def create(template)
      @libvirt.define_domain_xml(template)
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
