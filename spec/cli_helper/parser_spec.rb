
# frozen_string_literal: true

RSpec.describe Metalware::CliHelper::Parser do
  subject do
    described_class.new(
      Metalware::Cli.new
    )
  end

  before do
    stub_const('Metalware::CliHelper::CONFIG_PATH', test_config_path)
  end

  let(:test_config_path) { '/tmp/config.yaml' }

  describe 'default parsing' do
    def define_config_with_default(default_value)
      File.write(test_config_path, YAML.dump(
                                     'commands' => {
                                       'my_command' => {
                                         'options' => [{
                                           'tags' => ['-f', '--foo'],
                                           'default' => default_value,
                                         }],
                                       },
                                     },
                                     'global_options' => {}
      ))
    end

    it 'passes simple default values straight through as option default' do
      define_config_with_default(5)

      expect_any_instance_of(Commander::Command).to receive(:option).with(
        '-f', '--foo', # tags
        nil, # type
        { default: 5 }, # default
        '' # description
      )

      subject.parse_commands
    end

    it 'uses DynamicDefaults module to determine dynamic default values' do
      define_config_with_default('dynamic' => 'build_interface')

      stubbed_dynamic_default = 'eth3'
      expect(
        Metalware::CliHelper::DynamicDefaults
      ).to receive(:build_interface).and_return(stubbed_dynamic_default)

      expect_any_instance_of(Commander::Command).to receive(:option).with(
        '-f', '--foo', # tags
        nil, # type
        { default: stubbed_dynamic_default }, # default
        '' # description
      )

      subject.parse_commands
    end
  end
end
