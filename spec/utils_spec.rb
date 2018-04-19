
# frozen_string_literal: true

require 'utils'

RSpec.describe Metalware::Utils do
  describe '#commentify' do
    it 'wraps string and prepends comment character to each line' do
      my_string = 'this is my string, it should be wrapped and commented'
      result = described_class
               .commentify(my_string, comment_char: '#', line_length: 20)
      expect(result).to eq(
        <<-EOF.strip_heredoc.strip
        # this is my string,
        # it should be
        # wrapped and
        # commented
        EOF
      )
    end
  end
end
