
require 'active_support/core_ext/string/strip'

require 'templater'

FIXTURES_PATH = File.join(File.dirname(__FILE__), 'fixtures')
TEST_TEMPLATE_PATH = File.join(FIXTURES_PATH, 'template.erb')
TEST_REPO_PATH = File.join(FIXTURES_PATH, 'repo')

def expect_renders(templater, expected)
  # Strip trailing spaces from rendered output to make comparisons less
  # brittle.
  rendered = templater.file(TEST_TEMPLATE_PATH).gsub(/\s+\n/, "\n")

  expect(rendered).to eq(expected.strip_heredoc)
end

describe Metalware::Templater::Combiner do
  describe '#file' do
    context 'when templater passed no parameters' do
      it 'renders template with no extra parameters' do
        templater = Metalware::Templater::Combiner.new
        expected = <<-EOF
        This is a test template
        some_passed_value:
        some_repo_value:
        index: 0
        EOF

        expect_renders(templater, expected)
      end
    end

    context 'when templater passed parameters' do
      it 'renders template with extra passed parameters' do
        templater = Metalware::Templater::Combiner.new({
          some_passed_value: 'my_value'
        })
        expected = <<-EOF
        This is a test template
        some_passed_value: my_value
        some_repo_value:
        index: 0
        EOF

        expect_renders(templater, expected)
      end
    end

    context 'with repo' do
      before :each do
        stub_const('Metalware::Constants::REPO_PATH', TEST_REPO_PATH)
      end

      it 'renders template with repo parameters' do
        templater = Metalware::Templater::Combiner.new
        expected = <<-EOF
        This is a test template
        some_passed_value:
        some_repo_value: repo_value
        index: 0
        EOF

        expect_renders(templater, expected)
      end
    end
  end
end
