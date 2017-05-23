
module SpecUtils
  GENDERS_FILE = File.join(FIXTURES_PATH, 'genders')

  # Use `instance_exec` in many functions in this module to execute blocks the
  # context of the passed RSpec example group.
  class << self

    # Mocks.

    def use_mock_genders(example_group)
      example_group.instance_exec do
        stub_const("Metalware::Constants::NODEATTR_COMMAND", "nodeattr -f #{GENDERS_FILE}")
      end
    end

    def use_mock_templater(example_group)
      example_group.instance_exec do
        @templater = object_double(Metalware::Templater::Combiner.new)
        allow(
          Metalware::Templater::Combiner
        ).to receive(:new).and_return(
          @templater
        )
      end
    end

    def use_unit_test_config(example_group)
      example_group.instance_exec do
        stub_const(
          'Metalware::Constants::DEFAULT_CONFIG_PATH',
          SpecUtils.fixtures_config('unit-test.yaml')
        )
      end
    end

    # Expectations.

    def expect_it_templates_for_each_node(example_group)
      example_group.instance_exec do
        expect(
          Metalware::Templater::Combiner
        ).to receive(:new).with(
          hash_including(
            nodename: 'testnode01',
            index: 0
          )
        ).ordered
        expect(
          Metalware::Templater::Combiner
        ).to receive(:new).with(
          hash_including(
            nodename: 'testnode02',
            index: 1
          )
        ).ordered
      end
    end

    def expect_it_templates_for_single_node(example_group)
      example_group.instance_exec do
        expect(Metalware::Templater::Combiner).to receive(:new).with(
          hash_including(nodename: 'testnode01')
        )
      end
    end

    # Other shared utils.

    def run_command(command_class, *args, **options_hash)
      options = Commander::Command::Options.new
      options_hash.map do |option, value|
        option_setter = (option.to_s + '=').to_sym
        options.__send__(option_setter, value)
      end

      command_class.new(args, options)
    end

    def fixtures_config(config_file)
      File.join(FIXTURES_PATH, 'configs', config_file)
    end
  end
end
