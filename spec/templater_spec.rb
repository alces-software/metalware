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

require 'active_support/core_ext/string/strip'

require 'templater'
require 'spec_utils'
# require 'node'
require 'filesystem'
require 'validation/answer'
require 'namespaces/alces'

TEST_HUNTER_PATH = File.join(FIXTURES_PATH, 'cache/hunter.yaml')
EMPTY_REPO_PATH = File.join(FIXTURES_PATH, 'configs/empty-repo.yaml')

RSpec.describe Metalware::Templater do
  include AlcesUtils

  let(:filesystem) do
    FileSystem.setup do |fs|
      fs.write template_path, template.strip_heredoc
    end
  end

  # XXX Could adjust tests using this to only use template with parts they
  # need, to make them simpler and less dependent on changes to this or each
  # other.
  let(:template) do
    <<-EOF
    This is a test template
    some_passed_value: <%= domain.config.some_passed_value %>
    some_repo_value: <%= domain.config.some_repo_value %>
    erb_repo_value: <%= domain.config.erb_repo_value %>
    very_recursive_erb_repo_value: <%= domain.config.very_recursive_erb_repo_value %>
    nested.repo_value: <%= domain.config.nested ? domain.config.nested.repo_value : nil %>
    EOF
  end

  let(:template_path) { '/template' }

  def expect_renders(template_parameters, expected)
    filesystem.test do |_fs|
      # Strip trailing spaces from rendered output to make comparisons less
      # brittle.
      rendered = Metalware::Templater.render(
        alces, template_path, template_parameters
      ).gsub(/\s+\n/, "\n")

      expect(rendered).to eq(expected.strip_heredoc)
    end
  end

  describe '#render' do
    context 'without a repo' do
      it 'renders template with no extra parameters' do
        expected = <<-EOF
        This is a test template
        some_passed_value:
        some_repo_value:
        erb_repo_value:
        very_recursive_erb_repo_value:
        nested.repo_value:
        EOF

        expect_renders({}, expected)
      end
    end

    context 'with repo' do
      before do
        filesystem.with_repo_fixtures('repo')
      end

      it 'renders template with repo parameters' do
        expected = <<-EOF
        This is a test template
        some_passed_value:
        some_repo_value: repo_value
        erb_repo_value: repo_value
        very_recursive_erb_repo_value: repo_value
        nested.repo_value: nested_repo_value
        EOF

        expect_renders({}, expected)
      end

      context 'when template uses property of unset parameter' do
        let(:template) do
          'unset.parameter: <%= unset.parameter %>'
        end

        it 'raises' do
          filesystem.test do
            expect do
              described_class.render(alces, template_path, {})
            end.to raise_error NameError
          end
        end
      end
    end
  end
end
