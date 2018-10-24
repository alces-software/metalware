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

require 'underware/spec/alces_utils'
require 'constants'
require 'underware/dependency'
require 'build_methods'

module SpecUtils
  # Mocks.

  def mock_validate_genders_success
    mock_validate_genders(true, '')
  end

  # XXX Use this from Underware instead?
  def use_mock_genders(genders_file: 'genders/default')
    genders_path = File.join(FIXTURES_PATH, genders_file)

    nodeattr_command = 'Underware::Constants::NODEATTR_COMMAND'
    stub_const(nodeattr_command, "nodeattr -f #{genders_path}")
  end

  def use_unit_test_config
    stub_const(
      'Metalware::Constants::DEFAULT_CONFIG_PATH',
      fixtures_config('unit-test.yaml')
    )
  end

  def use_mock_determine_hostip_script
    stub_const(
      'Metalware::Constants::METALWARE_INSTALL_PATH',
      FIXTURES_PATH
    )
  end

  def use_mock_dependency
    allow_any_instance_of(
      Underware::Dependency
    ).to receive(:enforce)
  end

  def fake_download_error
    http_error = "418 I'm a teapot"
    allow(Metalware::Input).to receive(:download).and_raise(
      OpenURI::HTTPError.new(http_error, nil)
    )
    http_error
  end

  # Other shared utils.

  def fixtures_config(config_file)
    File.join(FIXTURES_PATH, 'configs', config_file)
  end

  def enable_output_to_stderr
    $rspec_suppress_output_to_stderr = false
  end

  def stub_build_method_for(node)
    stub_build_method = instance_double(
      Metalware::BuildMethods::BuildMethod
    ).as_null_object

    # Expect build method to be created, and stub the created object.
    expect(
      Metalware::BuildMethods
    ).to receive(
      :build_method_for
    ).at_least(:once).with(
      node
    ).and_return(stub_build_method)

    stub_build_method
  end

  private

  def mock_validate_genders(valid, error)
    allow(Underware::NodeattrInterface).to receive(
      :validate_genders_file
    ).and_return([valid, error])
  end
end
