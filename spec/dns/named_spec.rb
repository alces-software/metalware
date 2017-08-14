
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

require 'dns/named'
require 'config'
require 'filesystem'
require 'exceptions'

RSpec.describe Metalware::DNS::Named do
  let :config { Metalware::Config.new }
  let :named { Metalware::DNS::Named.new(config) }
  let :filesystem do
    FileSystem.setup do |fs|
      fs.with_minimal_repo
      fs.with_config_fixture('configs/unit-test.yaml', 'domain.yaml')
    end
  end

  context 'without a setup named server' do
    before :each { allow(named).to receive(:setup?).and_return(false) }

    it "errors if external dns isn't set" do
      expect do
        named.update
      end.to raise_error(Metalware::MissingExternalDNS)
    end

    it 'sets up the named server' do
      filesystem.test do
        named.update
      end
    end
  end

  context 'with a setup named server' do
    before :each { allow(named).to receive(:setup?).and_return(true) }

    it 'skips setting up the named server' do
      expect(named).not_to receive(:setup)
      named.update
    end
  end
end
