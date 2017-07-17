
require 'filesystem'
require 'spec_utils'


RSpec.describe Metalware::CommandHelpers::ConfigureCommand do
  TEST_COMMAND_NAME = :testcommand

  # Subclass of `ConfigureCommand` for use in tests, to test it independently
  # of any individual subclass.
  class TestCommand < Metalware::CommandHelpers::ConfigureCommand
    protected

    def setup(args, options)
    end

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

  it 'renders the hosts and genders files' do
    FileSystem.test do |fs|
      fs.with_minimal_repo

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
end
