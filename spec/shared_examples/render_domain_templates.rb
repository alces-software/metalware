
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

require 'spec_utils'

RSpec.shared_examples :render_domain_templates do |test_command|
  let :filesystem do
    FileSystem.setup do |fs|
      fs.with_minimal_repo
      fs.write(Metalware::Constants::GENDERS_PATH, existing_genders_contents)
      fs.write('/var/lib/metalware/repo/genders/default', genders_template)
    end
  end

  let :existing_genders_contents { "node01 nodes,other,groups\n" }

  # This uses an ERB tag so can test the invalid rendered template is saved.
  let :genders_template { 'some genders template <%= alces.index %>' }

  it 'renders the server config, hosts, and genders files' do
    SpecUtils.mock_validate_genders_success(self)

    filesystem.test do
      # Render this first, as many parts of the `alces` namespace could change
      # based on this.
      expect(Metalware::Templater).to receive(:render_to_file).with(
        instance_of(Metalware::Config),
        '/var/lib/metalware/repo/server.yaml',
        Metalware::Constants::SERVER_CONFIG_PATH,
        prepend_managed_file_message: true
      ).ordered.and_call_original

      # Genders file needs to be rendered before hosts, as how this is rendered
      # will effect the groups and nodes used when rendering the hosts file.
      expect(Metalware::Templater).to receive(:render_managed_file).with(
        instance_of(Metalware::Config),
        '/var/lib/metalware/repo/genders/default',
        Metalware::Constants::GENDERS_PATH
      ).ordered.and_call_original

      expect(Metalware::Templater).to receive(:render_managed_file).with(
        instance_of(Metalware::Config),
        '/var/lib/metalware/repo/hosts/default',
        Metalware::Constants::HOSTS_PATH
      ).ordered.and_call_original

      SpecUtils.run_command(test_command)
    end
  end

  context 'when invalid server config rendered' do
    let :server_config_template_path do
      File.join(Metalware::Config.new.repo_path, 'server.yaml')
    end

    let :build_interface { 'eth2' }

    before :each do
      filesystem.dump(
        server_config_template_path,
        build_interface: build_interface
      )

      expect(
        Metalware::Network
      ).to receive(:valid_interface?).with(build_interface).and_return(false)
    end

    it 'does not render hosts and genders files and gives error' do
      filesystem.test do
        expect do
          SpecUtils.run_command(test_command)
        end.to raise_error(Metalware::DomainTemplatesInternalError)

        # `server.yaml` and `hosts` not rendered.
        expect(File.exist?(Metalware::Constants::SERVER_CONFIG_PATH)).to be false
        expect(File.exist?('/etc/hosts')).to be false

        # Original `genders` content remains.
        expect(
          File.read(Metalware::Constants::GENDERS_PATH)
        ).to eq(existing_genders_contents)
      end
    end
  end

  context 'when invalid genders file rendered' do
    let :nodeattr_error { 'oh no genders' }
    before :each do
      SpecUtils.mock_validate_genders_failure(self, nodeattr_error)
    end

    let :genders_invalid_message do
      # A slightly hacky way to check that we include a note to use the
      # `configure rerender` command if this command is a `ConfigureCommand`.
      if test_command.ancestors.include?(Metalware::CommandHelpers::ConfigureCommand)
        /configure rerender/
      end
    end

    it 'does not render hosts file and gives error' do
      filesystem.test do
        expect do
          SpecUtils.run_command(test_command)
        end.to raise_error(Metalware::DomainTemplatesInternalError)

        # `hosts` not rendered as `genders` invalid.
        expect(File.exist?('/etc/hosts')).to be false

        # Original `genders` content remains.
        expect(
          File.read(Metalware::Constants::GENDERS_PATH)
        ).to eq(existing_genders_contents)

        # Invalid rendered genders available for inspection.
        expected_invalid_rendered_genders = 'some genders template 0'
        expect(
          File.read(Metalware::Constants::INVALID_RENDERED_GENDERS_PATH)
        ).to include(expected_invalid_rendered_genders)
      end
    end
  end
end
