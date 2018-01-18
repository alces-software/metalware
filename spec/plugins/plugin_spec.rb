
# frozen_string_literal: true

RSpec.describe Metalware::Plugins::Plugin do
  describe '#enabled_question_identifier' do
    it 'gives correct identifier for generated plugin enabled question' do
      plugin_dir_path = Pathname.new('path/to/some-plugin')
      plugin = described_class.new(plugin_dir_path)

      expect(
        plugin.enabled_question_identifier
      ).to eq 'metalware_internal--plugin_enabled--some-plugin'
    end
  end
end
