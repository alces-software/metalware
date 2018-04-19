# frozen_string_literal: true

require 'active_support/core_ext/string/strip'

module Metalware
  class Vm
    class Certificate
      attr_reader :node

      def initialize(node)
        @node = node
      end

      def exist?
        File.exist?(certificate_key_path)
      end

      def generate
        generate_certificate_key
        generate_certificate_info
        generate_server_certificates
        puts certificate_generation_message
      end

      private

      CERTS_DIR = '/var/lib/metalware/certs'

      def libvirt_host
        node.config.libvirt_host
      end

      def certificate_key_path
        File.join(CERTS_DIR, "#{libvirt_host}-key.pem")
      end

      def certificate_info_path
        File.join(CERTS_DIR, "#{libvirt_host}.info")
      end

      def ca_certificate_path
        File.join(CERTS_DIR, 'cacert.pem')
      end

      def ca_privkey_path
        File.join(CERTS_DIR, 'cakey.pem')
      end

      def certificate_path
        File.join(CERTS_DIR, "#{libvirt_host}-cert.pem")
      end

      def generate_certificate_key
        SystemCommand
          .run("certtool --generate-privkey > #{certificate_key_path}")
      end

      def generate_certificate_info
        File.open(certificate_info_path, 'w') do |f|
          f.puts 'organization = Alces Software'
          f.puts "cn = #{libvirt_host}"
          f.puts 'tls_www_server'
          f.puts 'encryption_key'
          f.puts 'signing_key'
        end
      end

      def generate_server_certificates
        SystemCommand.run("certtool --generate-certificate \
                          --load-privkey #{certificate_key_path} \
                          --load-ca-certificate #{ca_certificate_path} \
                          --load-ca-privkey #{ca_privkey_path} \
                          --template #{certificate_info_path} \
                          --outfile #{certificate_path}")
      end

      def certificate_generation_message
        <<~EOF.strip_heredoc
          The following certificates have been generated, copy them
          to the specified remote directory on #{libvirt_host}:

            from (local): #{certificate_path}
             to (remote): /etc/pki/libvirt/servercert.pem

            from (local): #{certificate_key_path}
             to (remote): /etc/pki/libvirt/private/serverkey.pem
      EOF
      end
    end
  end
end
