#==============================================================================
# Copyright (C) 2017 Stephen F. Norledge and Alces Software Ltd.
#
# This file/package is part of Alces Metalware.
#
# Alces Metalware is free software: you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License
# as published by the Free Software Foundation, either version 3 of
# the License, or (at your option) any later version.
#
# Alces Metalware is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this package.  If not, see <http://www.gnu.org/licenses/>.
#
# For more information on the Alces Metalware, please visit:
# https://github.com/alces-software/metalware
#==============================================================================

require 'active_support/core_ext/string/strip'

require 'templater'
require 'spec_utils'
require 'node'
require 'filesystem'

TEST_TEMPLATE_PATH = '/fixtures/template.erb'
UNSET_PARAMETER_TEMPLATE_PATH = '/fixtures/unset_parameter_template.erb'
TEST_HUNTER_PATH = File.join(FIXTURES_PATH, 'cache/hunter.yaml')


RSpec.describe Metalware::Templater do
  let :filesystem {
    FileSystem.setup do |fs|
      fs.with_fixtures('/', at: '/fixtures')
    end
  }

  def expect_renders(template_parameters, expected, config: Metalware::Config.new)
    filesystem.test do |fs|
      # Strip trailing spaces from rendered output to make comparisons less
      # brittle.
      rendered = Metalware::Templater.render(
        config, TEST_TEMPLATE_PATH, template_parameters
      ).gsub(/\s+\n/, "\n")

      expect(rendered).to eq(expected.strip_heredoc)
    end
  end

  describe '#render' do
    context 'when templater passed no parameters' do
      it 'renders template with no extra parameters' do
        expected = <<-EOF
        This is a test template
        some_passed_value:
        some_repo_value:
        erb_repo_value:
        very_recursive_erb_repo_value:
        nested.repo_value:
        alces.index: 0
        EOF

        expect_renders({}, expected)
      end
    end

    context 'when templater passed parameters' do
      it 'renders template with extra passed parameters' do
        template_parameters = ({
          some_passed_value: 'my_value'
        })
        expected = <<-EOF
        This is a test template
        some_passed_value: my_value
        some_repo_value:
        erb_repo_value:
        very_recursive_erb_repo_value:
        nested.repo_value:
        alces.index: 0
        EOF

        expect_renders(template_parameters, expected)
      end
    end

    context 'with repo' do
      before :each do
        @config = Metalware::Config.new
        filesystem.with_fixtures('repo', at: @config.repo_path)
      end

      it 'renders template with repo parameters' do
        expected = <<-EOF
        This is a test template
        some_passed_value:
        some_repo_value: repo_value
        erb_repo_value: 1
        very_recursive_erb_repo_value: repo_value
        nested.repo_value: nested_repo_value
        alces.index: 0
        EOF

        expect_renders({}, expected, config: @config)
      end

      it 'raises if maximum recursive config depth exceeded' do
        stub_const('Metalware::Constants::MAXIMUM_RECURSIVE_CONFIG_DEPTH', 3)

        filesystem.test do
          expect{
            Metalware::Templater.new(@config)
          }.to raise_error(Metalware::RecursiveConfigDepthExceededError)
        end
      end

      it 'raises if attempt to access a property of an unset parameter' do
        filesystem.test do
          expect {
            Metalware::Templater.render(@config, UNSET_PARAMETER_TEMPLATE_PATH, {})
          }.to raise_error Metalware::UnsetParameterAccessError
        end
      end
    end

    context 'when passed node not in genders file' do
      it 'does not raise error' do
        filesystem.test do
          expect {
            Metalware::Templater.render(
              Metalware::Config.new,
              TEST_TEMPLATE_PATH,
              nodename: 'not_in_genders_node01'
            )
          }.to_not raise_error
        end
      end
    end
  end

  describe 'magic alces namespace' do
    def expect_environment_dependent_parameters_present(magic_namespace)
      expect(magic_namespace.hostip).to eq('1.2.3.4')
      expect(magic_namespace.hosts_url).to eq 'http://1.2.3.4/metalware/system/hosts'
      expect(magic_namespace.genders_url).to eq 'http://1.2.3.4/metalware/system/genders'

      # Check hunter config.
      hunter_config = magic_namespace.hunter
      expect(hunter_config.testnode01).to eq('testnode01-mac')
      expect(hunter_config.testnode02).to eq('testnode02-mac')

      # Check genders config.
      genders_config = magic_namespace.genders
      expect(genders_config.masters).to eq(['login1'])
      expect(genders_config.domain).to eq(['login1', 'testnode01', 'testnode02', 'testnode03'])
      expect(genders_config.non_existent).to eq([])
    end

    before do
      # Stub this so mock hunter config used.
      stub_const('Metalware::Constants::HUNTER_PATH', TEST_HUNTER_PATH)

      SpecUtils.use_mock_determine_hostip_script(self)
      SpecUtils.use_mock_genders(self)
    end

    context 'when node has answers' do
      # XXX May be possible to combine this with other passed parameter test
      # below? They rely on file system however and this relies on a mocked
      # Node object.
      it 'provides access to the answers' do
        expect(Metalware::Node).to receive(:new).and_return(
          OpenStruct.new({
            answers: 'testnode01_answers',
            raw_config: {}
          })
        )

        config = Metalware::Config.new
        templater = Metalware::Templater.new(config, {nodename: 'testnode01'})

        expect(templater.config.alces.answers).to be_a(Metalware::MissingParameterWrapper)
        expect(templater.config.alces.answers.inspect).to eq('testnode01_answers')
      end
    end

    context 'without passed parameters' do
      it 'is created with default values' do
        templater = Metalware::Templater.new(Metalware::Config.new)
        magic_namespace = templater.config.alces

        expect(magic_namespace.index).to eq(0)
        expect(magic_namespace.nodename).to eq(nil)
        expect(magic_namespace.firstboot).to eq(nil)
        expect(magic_namespace.files).to eq(nil)
        expect(magic_namespace.kickstart_url).to eq(nil)
        expect(magic_namespace.build_complete_url).to eq(nil)
        expect_environment_dependent_parameters_present(magic_namespace)
      end
    end

    context 'with passed parameters' do
      it 'overrides defaults with parameter values, where applicable' do
        build_files = SpecUtils.create_mock_build_files_hash(self, 'testnode03')

        templater = Metalware::Templater.new(Metalware::Config.new, {
          nodename: 'testnode03',
          firstboot: true,
          files: build_files
        })
        magic_namespace = templater.config.alces

        expect(magic_namespace.index).to eq(2)
        expect(magic_namespace.nodename).to eq('testnode03')
        expect(magic_namespace.firstboot).to eq(true)
        expect(magic_namespace.kickstart_url).to eq('http://1.2.3.4/metalware/kickstart/testnode03')
        expect(magic_namespace.build_complete_url).to eq('http://1.2.3.4/metalware/exec/kscomplete.php?name=testnode03')

        # Can reach inside the passed `files` object.
        expect(
          magic_namespace.files.namespace01.first.raw
        ).to eq('/some/other/path')
        expect(
          magic_namespace.files.namespace02.first.raw
        ).to eq('another_file_in_repo')

        expect_environment_dependent_parameters_present(magic_namespace)
      end
    end

    context 'when no hunter config file present' do
      before do
        stub_const('Metalware::Constants::HUNTER_PATH', '/non-existent')
      end

      it 'loads the hunter parameter as an empty array' do
        templater = Metalware::Templater.new(Metalware::Config.new)
        magic_namespace = templater.config.alces
        expect(magic_namespace.hunter).to eq(Hashie::Mash.new)
      end
    end
  end
end
