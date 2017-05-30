
module Metalware
  module DeploymentServer
    class << self

      def ip
        SystemCommand.run(determine_hostip_script).chomp
      rescue SystemCommandError
        # If script failed for any reason fall back to using `hostname -i`,
        # which may or may not give the IP on the interface we actually want to
        # use (note: the dance with pipes is so we only get the last word in
        # the output, as I've had the IPv6 IP included first before, which
        # breaks all the things).
        # XXX Warn about falling back to this?
        SystemCommand.run(
          "hostname -i | xargs -d' ' -n1 | tail -n 2 | head -n 1"
        ).chomp
      end

      def system_file_url(system_file)
        url "system/#{system_file}"
      end

      def build_complete_url(node_name)
        if node_name
          url "exec/kscomplete.php?name=#{node_name}"
        end
      end

      def build_file_url(node_name, namespace, file_name)
        path = File.join(node_name , namespace.to_s , file_name)
        url path
      end

      private

      def url(url_path)
        full_path = File.join('metalware', url_path)
        URI.join("http://#{ip}", full_path).to_s
      end

      def determine_hostip_script
        File.join(
          Constants::METALWARE_INSTALL_PATH,
          'libexec/determine-hostip'
        )
      end

    end
  end
end
