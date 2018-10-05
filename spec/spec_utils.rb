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

require 'alces_utils'
require 'constants'
require 'dependency'

module SpecUtils
  # Use `instance_exec` in many functions in this module to execute blocks the
  # context of the passed RSpec example group.
  class << self
    # Mocks.

    def mock_validate_genders_success(example_group)
      mock_validate_genders(example_group, true, '')
    end

    def use_mock_genders(example_group, genders_file: 'genders/default')
      genders_path = File.join(FIXTURES_PATH, genders_file)

      example_group.instance_exec do
        nodeattr_command = 'Metalware::Constants::NODEATTR_COMMAND'
        stub_const(nodeattr_command, "nodeattr -f #{genders_path}")
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

    def use_mock_dependency(example_group)
      example_group.instance_exec do
        allow_any_instance_of(
          Metalware::Dependency
        ).to receive(:enforce)
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

    # Other shared utils.

    def fixtures_config(config_file)
      File.join(FIXTURES_PATH, 'configs', config_file)
    end

    def enable_output_to_stderr
      $rspec_suppress_output_to_stderr = false
    end

    private

    def mock_validate_genders(example_group, valid, error)
      example_group.instance_exec do
        allow(Metalware::NodeattrInterface).to receive(
          :validate_genders_file
        ).and_return([valid, error])
      end
    end
  end
end
