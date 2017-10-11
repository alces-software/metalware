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

require 'spec_helper'

require 'spec_utils'
require 'fileutils'
require 'config'
require 'constants'
require 'filesystem'
require 'validation/loader'
require 'validation/answer'

RSpec.describe do # Metalware::Node do
  # def node(name)
  #  Metalware::Node.new(config, name, **node_args)
  # end

  let :node_args { {} }

  let :testnode01 { node('testnode01') }
  let :testnode02 { node('testnode02') }
  let :testnode03 { node('testnode03') }
  let :config { Metalware::Config.new }

  before do
    SpecUtils.use_mock_genders(self)
  end

  # Not ideal testing the private method, however their is specific behaviour
  # required for the self node
  describe '#build_method_class' do
    let :build_node { Metalware::Node.new(config, 'name_to_be_mocked') }

    def build_method_class(node_name, build_method)
      allow(build_node).to receive(:name).and_return(node_name)
      repo_config = build_method.nil? ? {} : { build_method: build_method }
      allow(build_node).to receive(:repo_config).and_return(repo_config)
      build_node.send(:build_method_class)
    end

    context 'with a regular node' do
      xit 'returns the default (/kickstart) build method if not specified' do
        expected = Metalware::BuildMethods::Kickstarts::Pxelinux
        expect(build_method_class('build_node', nil)).to eq(expected)
      end

      xit 'returns the build method if specified' do
        expected = Metalware::BuildMethods::Basic
        expect(build_method_class('build_node', :basic)).to eq(expected)
      end

      xit 'errors if the self build method is used' do
        expect do
          build_method_class('build_node', :self)
        end.to raise_error(Metalware::SelfBuildMethodError)
      end
    end

    context "with the 'self' node" do
      xit 'returns the self build method if not specified' do
        expected = Metalware::BuildMethods::Self
        expect(build_method_class('self', nil)).to eq(expected)
      end

      xit 'returns the self build method if specified' do
        expected = Metalware::BuildMethods::Self
        expect(build_method_class('self', :self)).to eq(expected)
      end

      xit 'errors if the build method is not self' do
        expect do
          build_method_class('self', :basic)
        end.to raise_error(Metalware::SelfBuildMethodError)
      end
    end
  end
end
