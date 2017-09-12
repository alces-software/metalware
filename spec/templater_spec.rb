# frozen_string_literal: true

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
require 'validation/answer'

TEST_HUNTER_PATH = File.join(FIXTURES_PATH, 'cache/hunter.yaml')
EMPTY_REPO_PATH = File.join(FIXTURES_PATH, 'configs/empty-repo.yaml')

RSpec.describe Metalware::Templater do
  let :config do
    Metalware::Config.new
  end

  let :filesystem do
    FileSystem.setup do |fs|
      fs.write template_path, template.strip_heredoc
    end
  end

  # XXX Could adjust tests using this to only use template with parts they
  # need, to make them simpler and less dependent on changes to this or each
  # other.
  let :template do
    <<-EOF
    This is a test template
    some_passed_value: <%= some_passed_value %>
    some_repo_value: <%= some_repo_value %>
    erb_repo_value: <%= erb_repo_value %>
    very_recursive_erb_repo_value: <%= very_recursive_erb_repo_value %>
    nested.repo_value: <%= nested ? nested.repo_value : nil %>
    alces.index: <%= alces.index %>
    EOF
  end

  let :template_path { '/template' }

  def expect_renders(template_parameters, expected)
    filesystem.test do |_fs|
      # Strip trailing spaces from rendered output to make comparisons less
      # brittle.
      rendered = Metalware::Templater.render(
        config, template_path, template_parameters
      ).gsub(/\s+\n/, "\n")

      expect(rendered).to eq(expected.strip_heredoc)
    end
  end

  describe '#render' do
    context 'without a repo', real_fs: true do
      before :each do
        @config = Metalware::Config.new(EMPTY_REPO_PATH)
      end

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

      it 'renders template with extra passed parameters' do
        template_parameters = {
          some_passed_value: 'my_value',
        }
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
        filesystem.with_repo_fixtures('repo')
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

        expect_renders({}, expected)
      end

      it 'raises if maximum recursive config depth exceeded' do
        stub_const('Metalware::Constants::MAXIMUM_RECURSIVE_CONFIG_DEPTH', 3)

        filesystem.test do
          expect do
            Metalware::Templater.new(config)
          end.to raise_error(Metalware::RecursiveConfigDepthExceededError)
        end
      end

      context 'when template uses property of unset parameter' do
        let :template do
          'unset.parameter: <%= unset.parameter %>'
        end

        it 'raises' do
          filesystem.test do
            expect do
              Metalware::Templater.render(config, template_path, {})
            end.to raise_error Metalware::UnsetParameterAccessError
          end
        end
      end

      context 'when parsing recursive boolean values' do
        let :template do
          <<-EOF
          <% if recursive_true_repo_value -%>
          true worked
          <% end %>
          <% unless recursive_false_repo_value -%>
          false worked
          <% end %>
          EOF
        end

        it 'renders them as booleans not strings' do
          expected = <<-EOF
          true worked
          false worked
          EOF

          expect_renders({}, expected)
        end
      end
    end

    context 'when passed node not in genders file' do
      it 'does not raise error' do
        filesystem.test do
          expect do
            Metalware::Templater.render(
              config,
              template_path,
              nodename: 'not_in_genders_node01'
            )
          end.to_not raise_error
        end
      end
    end
  end

  describe '#render_to_file' do
    let :template { "simple template without ERB\n" }
    let :output_path { '/output' }
    let :output { File.read(output_path) }

    def render_to_file_with_block(&block)
      Metalware::Templater.render_to_file(
        config,
        template_path,
        output_path,
        &block
      )
    end

    it 'renders the template to the file by default' do
      filesystem.test do
        template_rendered = render_to_file_with_block

        expect(output).to eq(template)
        expect(template_rendered).to be true
      end
    end

    it 'renders template to the file if passed a block with truthy output' do
      filesystem.test do
        template_rendered = render_to_file_with_block(&:present?)

        expect(output).to eq(template)
        expect(template_rendered).to be true
      end
    end

    it 'does not render template to the file if passed a block with falsy output' do
      filesystem.test do
        template_rendered = render_to_file_with_block(&:empty?)

        expect(File.exist?(output_path)).to be false
        expect(template_rendered).to be false
      end
    end

    context 'when passed `prepend_managed_file_message` option' do
      it 'prepends the message to the rendered file' do
        filesystem.test do
          Metalware::Templater.render_to_file(
            config,
            template_path,
            output_path,
            prepend_managed_file_message: true
          )

          expect(output).to eq(
            "#{Metalware::Templater::MANAGED_FILE_MESSAGE}\n#{template}"
          )
        end
      end
    end
  end

  describe '#render_managed_file' do
    # XXX Similar to above.
    let :template { 'simple template without ERB' }
    let :output_path { '/output' }
    let :output { File.read(output_path) }

    let :rendered_file_section_regex do
      [
        Metalware::Templater::MANAGED_START,
        Metalware::Templater::MANAGED_COMMENT,
        template,
        Metalware::Templater::MANAGED_END,
      ].join("\n") + "\n"
    end

    def render_managed_file
      Metalware::Templater.render_managed_file(
        config,
        template_path,
        output_path
      )
    end

    def render_managed_file_with_block(&block)
      Metalware::Templater.render_managed_file(
        config,
        template_path,
        output_path,
        &block
      )
    end

    context 'when file does not exist already' do
      it 'renders template within markers' do
        filesystem.test do
          render_managed_file
          expect(output).to match(rendered_file_section_regex)
        end
      end

      # XXX Following two tests similar to those for `render_to_file` above.
      it 'renders template if passed a block with truthy output' do
        filesystem.test do
          template_rendered = render_managed_file_with_block(&:present?)

          expect(output).to match(rendered_file_section_regex)
          expect(template_rendered).to be true
        end
      end

      it 'does not render template if passed a block with falsy output' do
        filesystem.test do
          template_rendered = render_managed_file_with_block(&:empty?)

          expect(File.exist?(output_path)).to be false
          expect(template_rendered).to be false
        end
      end
    end

    context 'when file exists without markers' do
      let :existing_contents { "existing file contents\n" }

      let :rendered_file_regex do
        [existing_contents, "\n", rendered_file_section_regex].join
      end

      before :each do
        filesystem.write(output_path, existing_contents)
      end

      it 'renders template within markers at bottom of existing file' do
        filesystem.test do
          render_managed_file
          expect(output).to match(rendered_file_regex)
        end
      end
    end

    context 'when file exists with markers' do
      let :existing_contents do
        <<-EOF.strip_heredoc
        BEFORE

        #{Metalware::Templater::MANAGED_START}
        previous rendered template
        #{Metalware::Templater::MANAGED_END}

        AFTER
        EOF
      end

      let :rendered_file_regex do
        "BEFORE\n\n" + rendered_file_section_regex + "\n\nAFTER"
      end

      before :each do
        filesystem.write(output_path, existing_contents)
      end

      it 'renders template and replaces within markers' do
        filesystem.test do
          render_managed_file
          expect(output).to match(rendered_file_regex)
        end
      end

      it 'is idempotent' do
        filesystem do
          3.times { render_managed_file }

          # So long as the existing file and the rendered template remain the
          # same, the final template output should also remain the same after
          # repeated renderings.
          expect(output).to match(rendered_file_regex)
        end
      end
    end
  end

  # XXX These tests test `Templating::MagicNamespace` via the `Templater`; this
  # is useful to check they work together but we may want to test some things
  # directly on the `MagicNamespace`.
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
      expect(genders_config.cluster).to eq(['login1', 'testnode01', 'testnode02', 'testnode03'])
      expect(genders_config.non_existent).to eq([])
    end

    let :filesystem do
      FileSystem.setup do |fs|
        fs.with_repo_fixtures 'repo'
      end
    end

    before do
      SpecUtils.use_mock_determine_hostip_script(self)
      SpecUtils.use_mock_genders(self)
    end

    # XXX May be possible to combine these with other passed parameter testsgqic
    # below?
    describe 'answers' do
      before :each do
        # Turns off answer validation as the configure.yaml has not been created
        allow_any_instance_of(Metalware::Validation::Answer).to \
          receive(:success?).and_return(true)
        filesystem.dump '/var/lib/metalware/answers/nodes/testnode01.yaml',
                        some_question: 'some_answer'
      end

      let :answers { templater.config.alces.answers }

      context 'when node passed' do
        let :templater do
          Metalware::Templater.new(config, nodename: 'testnode01')
        end

        it 'can access answers for the node' do
          filesystem.test do
            expect(answers.some_question).to eq('some_answer')
          end
        end

        it "raises if attempt to access an answer which isn't present" do
          filesystem.test do
            expect { answers.invalid_question }.to raise_error(Metalware::MissingParameterError)
          end
        end
      end

      context 'when no node passed' do
        let :templater do
          Metalware::Templater.new(config)
        end

        it 'returns nil for all values in answers namespace' do
          filesystem.test do
            expect(answers.anything).to be nil
          end
        end
      end
    end

    context 'with cache files present' do
      before :each do
        filesystem.with_hunter_cache_fixture 'cache/hunter.yaml'
        filesystem.with_group_cache_fixture 'cache/groups.yaml'
      end

      it 'is created with default values when no parameters passed' do
        filesystem.test do
          templater = Metalware::Templater.new(config)
          magic_namespace = templater.config.alces

          expect(magic_namespace.index).to eq(0)
          expect(magic_namespace.group_index).to eq(0)
          expect(magic_namespace.nodename).to eq('')
          expect(magic_namespace.firstboot).to eq(nil)
          expect(magic_namespace.files).to eq(nil)
          # The kickstart and build URL tests have been patched to an empty nodename
          # Ideally in the future this should return nil
          expect(magic_namespace.kickstart_url).to eq('http://1.2.3.4/metalware/kickstart/')
          expect(magic_namespace.build_complete_url).to eq('http://1.2.3.4/metalware/exec/kscomplete.php?name=')
          expect_environment_dependent_parameters_present(magic_namespace)
        end
      end

      it 'overrides defaults with applicable parameter values when parameters passed' do
        filesystem.test do
          build_files = SpecUtils.create_mock_build_files_hash(
            self, config: config, node_name: 'testnode03'
          )

          templater = Metalware::Templater.new(config, nodename: 'testnode03',
                                                       firstboot: true,
                                                       files: build_files)
          magic_namespace = templater.config.alces

          expect(magic_namespace.index).to eq(3)
          expect(magic_namespace.group_index).to eq(2)
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
    end

    context 'when no hunter cache file present' do
      it 'loads the hunter parameter as an empty Hashie' do
        filesystem.test do
          templater = Metalware::Templater.new(config)
          magic_namespace = templater.config.alces
          expect(magic_namespace.hunter.to_h).to eq(Hashie::Mash.new)
        end
      end
    end
  end
end
