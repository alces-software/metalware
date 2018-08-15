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

RSpec.describe Metalware::BuildMethods::BuildMethod do
  class TestBuildMethod < described_class
    def staging_templates
      []
    end
  end

  subject do
    TestBuildMethod.new(node)
  end

  let(:node) { Metalware::Namespaces::Node.create(alces, 'node01') }
  let(:alces) { Metalware::Namespaces::Alces.new }
  let(:templater) do
    Metalware::Staging.template
  end

  let(:template_path) { '/path/to/template' }
  let(:rendered_path) { '/path/to/rendered' }

  let(:mock_files) do
    FileSystem.root_setup do |fs|
      fs.create template_path
      fs.create rendered_path
    end

    Metalware::Constants::HASH_MERGER_DATA_STRUCTURE.new(
      some_section: [{
        template_path: template_path,
        rendered_path: rendered_path,
      }]
    )
  end

  let(:mock_files_with_errors) do
    Metalware::Constants::HASH_MERGER_DATA_STRUCTURE.new(
      some_section: [{
        error: 'error',
      }]
    )
  end

  describe '#render_staging_templates' do
    it 'renders node build files to staging' do
      allow(node).to receive(:files).and_return(mock_files)

      expect(templater).to receive(:render).with(
        node, template_path, rendered_path, mkdir: true
      )
      subject.render_staging_templates(templater)
    end

    it 'does not render build files with errors' do
      allow(node).to receive(:files).and_return(mock_files_with_errors)

      expect(templater).not_to receive(:render)
      subject.render_staging_templates(templater)
    end

    it 'renders plugin build files to staging' do
      mock_plugin = OpenStruct.new
      plugin_namespace =
        Metalware::Namespaces::Plugin.new(mock_plugin, node: node)
      allow(node).to receive(:plugins).and_return([plugin_namespace])
      allow(plugin_namespace).to receive(:files).and_return(mock_files)

      expect(templater).to receive(:render).with(
        plugin_namespace, template_path, rendered_path, mkdir: true
      )
      subject.render_staging_templates(templater)
    end
  end
end
