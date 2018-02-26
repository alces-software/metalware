# frozen_string_literal

require 'alces_utils'

RSpec.shared_context 'overview context' do
  include AlcesUtils

  let :config_value { 'config_value' }
  let :static { 'static' }
  let :fields do
    [
      { header: 'heading1', value: static },
      { header: 'heading2', value: '<%= scope.config.key %>' },
      { header: 'heading3', value: '' },
      { header: 'missing-value' },
      { value: 'missing-header' }
    ]
  end

  AlcesUtils.mock self, :each do
    ['group1', 'group2', 'group3'].map do |group|
      config(mock_group(group), key: config_value)
    end
  end
end

