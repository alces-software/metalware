
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
        erb_repo_value:
        alces.index: 0
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
        erb_repo_value:
        alces.index: 0
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
        erb_repo_value: 1
        alces.index: 0
        EOF

        expect_renders(templater, expected)
      end
    end
  end

  describe 'magic alces namespace' do
    before do
      # Stub this so mock `determine-hostip` script used.
      stub_const('Metalware::Constants::METALWARE_INSTALL_PATH', FIXTURES_PATH)
    end

    context 'without passed parameters' do
      it 'is created with default values' do
        templater = Metalware::Templater::Combiner.new
        magic_namespace = templater.parsed_hash[:alces]

        expect(magic_namespace[:index]).to eq(0)
        expect(magic_namespace[:nodename]).to eq(nil)
        expect(magic_namespace[:hostip]).to eq('1.2.3.4')
      end
    end

    context 'with passed parameters' do
      it 'overrides defaults with parameter values, where applicable' do
        templater = Metalware::Templater::Combiner.new({
          nodename: 'testnode04',
          index: 3
        })
        magic_namespace = templater.parsed_hash[:alces]

        expect(magic_namespace[:index]).to eq(3)
        expect(magic_namespace[:nodename]).to eq('testnode04')
        expect(magic_namespace[:hostip]).to eq('1.2.3.4')
      end
    end
  end
end
