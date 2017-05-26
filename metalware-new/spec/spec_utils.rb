
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

    def use_unit_test_config(example_group)
      example_group.instance_exec do
        stub_const(
          'Metalware::Constants::DEFAULT_CONFIG_PATH',
          SpecUtils.fixtures_config('unit-test.yaml')
        )
      end
    end

    def use_mock_determine_hostip_script(example_group)
      example_group.instance_exec do
        stub_const(
          'Metalware::Constants::METALWARE_INSTALL_PATH',
          FIXTURES_PATH
        )
      end
    end

    def fake_download_error(example_group)
      http_error = "418 I'm a teapot"
      example_group.instance_exec do
        allow(Metalware::Input).to receive(:download).and_raise(
          OpenURI::HTTPError.new(http_error, nil)
        )
      end
      http_error
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
