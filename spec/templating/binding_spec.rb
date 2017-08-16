
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

require 'templating/binding'
require 'filesystem'
require 'config'

RSpec.describe Metalware::Templating::Binding do
  let :config { Metalware::Config.new }
  let :domain_binding { Metalware::Templating::Binding.build(config) }

  let :filesystem do
    FileSystem.setup do |fs|
      fs.with_minimal_repo
      fs.with_repo_fixtures('repo')
    end
  end

  def evaluate(section, cmd)
    result = send("#{section}_binding").eval(cmd)
    result.to_s
  end

  context 'with a domain level Binding' do
    it 'Can retrieve a non-erb value from the config' do
      filesystem.test do
        expect(evaluate('domain', 'some_repo_value')).to eq('repo_value')
      end
    end

    it 'Can retrieve a non-erb nested config value' do
      filesystem.test do
        result = evaluate('domain', 'nested.more_nesting.repo_value')
        expect(result).to eq('even_more_nesting')
      end
    end

    it 'Replaces erb template values' do
      filesystem.test do
        result = evaluate('domain', 'first_level_erb_repo_value')
        expect(result).to eq('repo_value')
      end
    end
  end
end
