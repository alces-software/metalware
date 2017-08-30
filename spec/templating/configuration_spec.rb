
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

require 'templating/configuration'
require 'config'
require 'node'

RSpec.describe Metalware::Templating::Configuration do
  let :config { Metalware::Config.new }
  let :testnode do
    double('Metalware::Node',
           groups: ['group1', 'group2'],
           name: 'testnode')
  end

  def configuration_node(node_name)
    Metalware::Templating::Configuration.for_node(node_name, config: config)
  end

  describe '#configs' do
    it 'returns domain and self for the metalware master node' do
      expect(configuration_node('self').configs).to eq(['domain', 'self'])
    end

    it 'returns the configs for a regular node' do
      allow(Metalware::Node).to receive(:new).and_return(testnode)
      expected_configs = ['domain', 'group2', 'group1', testnode.name]
      expect(configuration_node(testnode.name).configs).to eq(expected_configs)
    end
  end
end
