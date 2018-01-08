# frozen_string_literal: true

require 'config'
require 'libvirt'
require 'metal_log'
require 'namespaces/alces'

module Metalware
  class Vm
    attr_reader :node

    def initialize(node)
      @node = node
      @libvirt ||= certificate? ? libvirt : generate_certificate
    end

    def kill
      puts "Killing node #{node.name}.."
      domain.destroy
    end

    def on
      puts "Powering up node #{node.name}.."
      domain.create
    end

    def off
      puts "Powering down node #{node.name}.."
      domain.shutdown
    end

    def reboot
      puts "Rebooting node #{node.name}.."
      domain.reboot
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
      domain.destroy
      puts "Removing domain #{node.name}"
      domain.undefine
      vol = storage.lookup_volume_by_name(node.name)
      puts "Removing #{node.name} storage volume"
      vol.delete
    end

    private

    CERTS_DIR = '/var/lib/metalware/certs'

    CERT_GENERATION_MSG = <<-EOF
    The following certificates have been generated, copy them
    to the specified remote directory on #{libvirt_host}:

      from (local): #{CERTS_DIR}/#{libvirt_host}-{key,cert}.pem
       to (remote): /etc/pki/libvirt/{servercert.pem,/private/serverkey.pem}
    EOF

    def libvirt_host
      node.config.libvirt_host
    end

    def libvirt
      Libvirt.open("qemu://#{libvirt_host}/system")
    end

    def certificate?
      File.exist?("#{CERTS_DIR}/#{libvirt_host}-key.pem")
    end

    def generate_certificate
      generate_certificate_key
      generate_certificate_info
      generate_server_certificates
      puts CERT_GENERATION_MSG
      exit
    end

    def generate_certificate_key
      SystemCommand.run("certtool --generate-privkey > #{CERTS_DIR}/#{libvirt_host}-key.pem")
    end

    def generate_certificate_info
      File.open("#{CERTS_DIR}/#{libvirt_host}.info", 'w') do |f|
        f.puts 'organization = Alces Software'
        f.puts "cn = #{libvirt_host}"
        f.puts 'tls_www_server'
        f.puts 'encryption_key'
        f.puts 'signing_key'
      end
    end

    def generate_server_certificates
      SystemCommand.run("certtool --generate-certificate \
                        --load-privkey #{CERTS_DIR}/#{libvirt_host}-key.pem \
                        --load-ca-certificate #{CERTS_DIR}/cacert.pem \
                        --load-ca-privkey #{CERTS_DIR}/cakey.pem \
                        --template #{CERTS_DIR}/#{libvirt_host}.info \
                        --outfile #{CERTS_DIR}/#{libvirt_host}-cert.pem")
    end

    def domain
      @libvirt.lookup_domain_by_name(node.name)
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
      @storage ||= @libvirt.lookup_storage_pool_by_name(node.config.vm_disk_pool)
    end

    def render_template(type)
      path = "/var/lib/metalware/repo/libvirt/#{type}.xml"
      node.render_erb_template(File.read(path))
    end
  end
end
