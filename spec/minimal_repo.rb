
# frozen_string_literal: true

#==============================================================================
# Copyright (C) 2017 Stephen F. Norledge and Alces Software Ltd.
#
# This file/package is part of Alces Metalware.
#
# Alces Metalware is free software: you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License
# as published by the Free Software Foundation, either version 3 of
# the License, or (at your option) any later version.
#
# Alces Metalware is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this package.  If not, see <http://www.gnu.org/licenses/>.
#
# For more information on the Alces Metalware, please visit:
# https://github.com/alces-software/metalware
#==============================================================================

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
