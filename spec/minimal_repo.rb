
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

require 'network_interface'

module MinimalRepo
  class << self
    FILES = {
      '.git/': nil,
      'files/': nil,
      'pxelinux/default':
        "<%= alces.firstboot ? 'FIRSTBOOT' : 'NOT_FIRSTBOOT' %>\n",
      'kickstart/default': '',
      'uefi-kickstart/default': '',
      'basic/default': '',
      'hosts/default': '',
      'named/default': '',
      'named/forward/default': '',
      'named/reverse/default': '',
      'genders/default': '',
      'dhcp/default': '',
      'config/domain.yaml': '',
      'configure.yaml': YAML.dump(questions: [],
                                  domain: [],
                                  group: [],
                                  node: [],
                                  local: []),
      # Define the build interface to be whatever the first interface is; this
      # should always be sufficient for testing purposes.
      'server.yaml': YAML
            .dump(build_interface: NetworkInterface.interfaces.first),
    }.freeze

    ABSOLUTE_FILES = {
      '/var/lib/tftpboot/pxelinux.cfg/': nil,
    }.freeze

    def create_at(path)
      FILES.each do |file, content|
        file_path = File.join(path, file.to_s)
        make_file(file_path, content)
      end
      ABSOLUTE_FILES.each { |f, c| make_file(f.to_s, c) }
    end

    private

    def make_file(abs_file, content)
      just_dir = content.nil?
      FileUtils.mkdir_p(dir_path(abs_file, just_dir: just_dir))
      File.write(abs_file, content) unless just_dir
    end

    def dir_path(file_path, just_dir:)
      if just_dir
        file_path
      else
        File.dirname(file_path)
      end
    end
  end
end
