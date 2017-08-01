
# frozen_string_literal: true

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
      expect(Metalware::Templater).to receive(:render_to_file).with(
        instance_of(Metalware::Config),
        '/var/lib/metalware/repo/genders/default',
        Metalware::Constants::GENDERS_PATH,
        prepend_managed_file_message: true
      ).ordered.and_call_original

      expect(Metalware::Templater).to receive(:render_to_file).with(
        instance_of(Metalware::Config),
        '/var/lib/metalware/repo/hosts/default',
        Metalware::Constants::HOSTS_PATH,
        prepend_managed_file_message: true
      ).ordered.and_call_original

      SpecUtils.run_command(test_command)
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
        expect(Metalware::Io).to receive(:abort)

        # Error should be shown including the `nodeattr` error message and
        # where to find the invalid genders file.
        error_parts = [
          /invalid/,
          /#{nodeattr_error}/,
          /#{Metalware::Constants::INVALID_RENDERED_GENDERS_PATH}/,
        ].tap do |parts|
          parts << genders_invalid_message if genders_invalid_message
        end
        error_parts.each do |fragment|
          expect(Metalware::Output).to receive(:stderr).with(fragment).ordered
        end

        SpecUtils.run_command(test_command)

        # `hosts` not rendered as `genders` invalid.
        expect(File.exist?('/etc/hosts')).to be false

        # Original `genders` content remains.
        expect(
          File.read(Metalware::Constants::GENDERS_PATH)
        ).to eq(existing_genders_contents)

        # Invalid rendered genders available for inspection.
        expected_invalid_rendered_genders = \
          "#{Metalware::Templater::MANAGED_FILE_MESSAGE}\nsome genders template 0"
        expect(
          File.read(Metalware::Constants::INVALID_RENDERED_GENDERS_PATH)
        ).to eq(expected_invalid_rendered_genders)
      end
    end
  end
end
