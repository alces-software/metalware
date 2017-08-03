
# frozen_string_literal: true

module MinimalRepo
  class << self
    DIRECTORIES = [
      '.git',
      'config',
      'hosts',
      'genders',
      'dhcp',
      'files',
      'pxelinux',
      'kickstart',
    ].freeze

    FILES = {
      'pxelinux/default': "<%= alces.firstboot ? 'FIRSTBOOT' : 'NOT_FIRSTBOOT' %>\n",
      'kickstart/default': '',
      'hosts/default': '',
      'genders/default': '',
      'dhcp/default': '',
      'config/domain.yaml': '',
      'configure.yaml': YAML.dump(questions: {},
                                  domain: {},
                                  group: {},
                                  node: {}),
      # Define the build interface to be whatever the first interface is; this
      # should always be sufficient for testing purposes.
      'server.yaml': YAML.dump(build_interface: NetworkInterface.interfaces.first),
    }.freeze

    def create_at(path)
      create_directories_at(path)
      create_files_at(path)
    end

    private

    def create_directories_at(path)
      DIRECTORIES.each do |dir|
        dir_path = File.join(path, dir)
        FileUtils.mkdir_p(dir_path)
      end
    end

    def create_files_at(path)
      FILES.each do |file, content|
        file_path = File.join(path, file.to_s)
        File.write(file_path, content)
      end
    end
  end
end
