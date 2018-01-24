
RSpec.describe Metalware::Plugins::Plugin do
  let :plugin_dir_path { Pathname.new('/path/to/some-plugin') }
  subject { described_class.new(plugin_dir_path) }

  describe '#enabled_question_identifier' do
    it 'gives correct identifier for generated plugin enabled question' do
      expect(
        subject.enabled_question_identifier
      ).to eq 'metalware_internal--plugin_enabled--some-plugin'
    end
  end
end
