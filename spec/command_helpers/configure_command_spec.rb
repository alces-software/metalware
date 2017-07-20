
# frozen_string_literal: true

require 'filesystem'
require 'spec_utils'

RSpec.describe Metalware::CommandHelpers::ConfigureCommand do
  TEST_COMMAND_NAME = :testcommand

  # Subclass of `ConfigureCommand` for use in tests, to test it independently
  # of any individual subclass.
  class TestCommand < Metalware::CommandHelpers::ConfigureCommand
    protected

    def setup(args, options); end

    # Overridden to be three element array with third a valid `configure.yaml`
    # questions section; `BaseCommand` expects command classes to be namespaced
    # by two modules, and `ConfigureCommand` determines questions section,
    # which must be valid, from the class name.
    def class_name_parts
      [:some, :namespace, :domain]
    end

    def answers_file
      '/var/lib/metalware/answers/some_file.yaml'
    end
  end

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

  it 'renders the hosts and genders files' do
    SpecUtils.mock_validate_genders_success(self)

    filesystem.test do
      # Genders file needs to be rendered first, as how this is rendered will
      # effect the groups and nodes used when rendering the hosts file.
      expect(Metalware::Templater).to receive(:render_to_file).with(
        instance_of(Metalware::Config),
        '/var/lib/metalware/repo/genders/default',
        Metalware::Constants::GENDERS_PATH
      ).ordered.and_call_original

      expect(Metalware::Templater).to receive(:render_to_file).with(
        instance_of(Metalware::Config),
        '/var/lib/metalware/repo/hosts/default',
        Metalware::Constants::HOSTS_PATH
      ).ordered.and_call_original

      SpecUtils.run_command(TestCommand)
    end
  end

  context 'when invalid genders file rendered' do
    let :nodeattr_error { 'oh no genders' }
    before :each do
      SpecUtils.mock_validate_genders_failure(self, nodeattr_error)
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
        ]
        error_parts.each do |fragment|
          expect(Metalware::Output).to receive(:stderr).with(fragment).ordered
        end

        SpecUtils.run_command(TestCommand)

        # `hosts` not rendered as `genders` invalid.
        expect(File.exist?('/etc/hosts')).to be false

        # Original `genders` content remains.
        expect(
          File.read(Metalware::Constants::GENDERS_PATH)
        ).to eq(existing_genders_contents)

        # Invalid rendered genders available for inspection.
        expect(
          File.read(Metalware::Constants::INVALID_RENDERED_GENDERS_PATH)
        ).to eq('some genders template 0')
      end
    end
  end
end
