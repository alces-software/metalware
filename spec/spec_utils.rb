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

module SpecUtils
  GENDERS_FILE = File.join(FIXTURES_PATH, 'genders')

  # Use `instance_exec` in many functions in this module to execute blocks the
  # context of the passed RSpec example group.
  class << self

    # Mocks.

    def use_mock_genders(example_group)
      example_group.instance_exec do
        stub_const("Metalware::Constants::NODEATTR_COMMAND", "nodeattr -f #{GENDERS_FILE}")
      end
    end

    def use_unit_test_config(example_group)
      example_group.instance_exec do
        stub_const(
          'Metalware::Constants::DEFAULT_CONFIG_PATH',
          SpecUtils.fixtures_config('unit-test.yaml')
        )
      end
    end

    def use_mock_determine_hostip_script(example_group)
      example_group.instance_exec do
        stub_const(
          'Metalware::Constants::METALWARE_INSTALL_PATH',
          FIXTURES_PATH
        )
      end
    end

    def fake_download_error(example_group)
      http_error = "418 I'm a teapot"
      example_group.instance_exec do
        allow(Metalware::Input).to receive(:download).and_raise(
          OpenURI::HTTPError.new(http_error, nil)
        )
      end
      http_error
    end

    def create_mock_build_files_hash(example_group, node_name)
      SpecUtils.use_unit_test_config(example_group)
      SpecUtils.fake_download_error(example_group)

      example_group.instance_exec do
        config = Metalware::Config.new
        node = Metalware::Node.new(config, node_name)
        Metalware::BuildFilesRetriever.new(
          node_name, config
        ).retrieve(node.build_files)
      end
    end

    def mock_repo_exists(example_group)
      example_group.instance_exec do
        allow_any_instance_of(
          Metalware::Repo
        ).to receive(:exists?).and_return(true)
      end
    end

    # Other shared utils.

    def run_command(command_class, *args, **options_hash)
      options = Commander::Command::Options.new
      options_hash.map do |option, value|
        option_setter = (option.to_s + '=').to_sym
        options.__send__(option_setter, value)
      end

      command_class.new(args, options)
    end

    def fixtures_config(config_file)
      File.join(FIXTURES_PATH, 'configs', config_file)
    end
  end
end
