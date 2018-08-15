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

require 'tempfile'
require 'yaml'
require 'highline'

require 'configurator'
require 'validation/loader'
require 'alces_utils'

RSpec.describe Metalware::Configurator do
  include AlcesUtils

  let(:input) do
    Tempfile.new
  end

  let(:output) do
    Tempfile.new
  end

  # Spoofs HighLine to always return the testing version of highline
  let!(:highline) do
    hl = HighLine.new(input, output)
    allow(HighLine).to receive(:new).and_return(hl)
    hl
  end

  let(:answers) do
    loader.domain_answers
  end

  let(:higher_level_answer_files) { [] }

  let(:loader) { Metalware::Validation::Loader.new }

  let(:configurator) do
    make_configurator
  end

  def make_configurator
    Metalware::Configurator.new(
      alces,
      questions_section: :domain
    )
  end

  def define_questions(**h)
    v = Metalware::Validation::Configure.new(h)
    allow(Metalware::Validation::Configure).to receive(:new).and_return(v)
  end

  def redirect_stdout
    $stdout = tmp = Tempfile.new
    yield
    tmp.close
  rescue StandardError => e
    $stdout.rewind
    STDERR.puts $stdout.read
    raise e
  ensure
    $stdout = STDOUT
  end

  def configure_with_input(input_string, test_obj: configurator)
    redirect_stdout do
      input.read # Move to the end of the file
      count = input.write(input_string)
      input.pos = (input.pos - count) # Move to the start of new content
      test_obj.configure
      reset_alces
    end
  end

  def configure_with_answers(answers, test_obj: configurator)
    # Each answer must be entered followed by a newline to terminate it.
    configure_with_input(answers.join("\n") + "\n", test_obj: test_obj)
  end

  # Do not want to use readline to get input in tests as tests will then
  # hang waiting for input.
  before do
    allow(described_class).to receive(:use_readline).and_return(false)
  end

  describe '#configure' do
    it 'asks questions with type `string`' do
      define_questions(domain: [
                         {
                           identifier: 'string_q',
                           question: 'Can you enter a string?',
                           type: 'string',
                         },
                       ])

      configure_with_answers(['My string'])

      expect(answers).to eq(string_q: 'My string')
    end

    it 'asks questions with no `type` as `string`' do
      define_questions(domain: [
                         {
                           identifier: 'string_q',
                           question: 'Can you enter a string?',
                         },
                       ])

      configure_with_answers(['My string'])

      expect(answers).to eq(string_q: 'My string')
    end

    it 'asks questions with type `integer`' do
      define_questions(domain: [
                         {
                           identifier: 'integer_q',
                           question: 'Can you enter an integer?',
                           type: 'integer',
                         },
                       ])

      configure_with_answers(['7'])

      expect(answers).to eq(integer_q: 7)
    end

    it "uses confirmation for questions with type 'boolean'" do
      define_questions(domain: [
                         {
                           identifier: 'boolean_q',
                           question: 'Should this cluster be awesome?',
                           type: 'boolean',
                         },
                       ])

      expect(highline).to receive(
        :agree
      ).with(
        # Note that progress and an indication of what the input should be has
        # been appended to the asked question.
        'Should this cluster be awesome? (1/1) [yes/no]'
      ).and_call_original

      configure_with_answers(['yes'])

      expect(answers).to eq(boolean_q: true)
    end

    it "offers choices for question with type 'choice'" do
      define_questions(domain: [
                         {
                           identifier: 'choice_q',
                           question: 'What choice would you like?',
                           choices: ['foo', 'bar'],
                         },
                       ])

      expect(highline).to receive(
        :choose
      ).with(
        'foo', 'bar'
      ).and_call_original

      configure_with_answers(['bar'])

      expect(answers).to eq(choice_q: 'bar')
    end

    it 'asks all questions in order' do
      define_questions(domain: [
                         {
                           identifier: 'string_q',
                           question: 'String?',
                           type: 'string',
                         },
                         {
                           identifier: 'integer_q',
                           question: 'Integer?',
                           type: 'integer',
                         },
                         {
                           identifier: 'boolean_q',
                           question: 'Boolean?',
                           type: 'boolean',
                         },
                       ])

      configure_with_answers(['Some string', '11', 'no'])

      expect(answers).to eq(
        string_q: 'Some string',
        integer_q: 11,
        boolean_q: false
      )
    end

    it 'saves nothing if default available and no input given' do
      str_ans = 'I am a little teapot!!'
      erb_ans = '<%= I_am_an_erb_tag %>'

      define_questions(domain: [
                         {
                           identifier: 'string_q',
                           question: 'String?',
                           type: 'string',
                           default: str_ans,
                         },
                         {
                           identifier: 'string_erb',
                           question: 'Erb?',
                           default: erb_ans,
                         },
                         {
                           identifier: 'integer_q',
                           question: 'Integer?',
                           type: 'integer',
                           default: 10,
                         },
                         {
                           identifier: 'true_boolean_q',
                           question: 'Boolean?',
                           type: 'boolean',
                           default: true,
                         },
                         {
                           identifier: 'false_boolean_q',
                           question: 'More boolean?',
                           type: 'boolean',
                           default: false,
                         },
                       ])

      configure_with_answers([''] * 5)

      expect(answers).to eq({})
    end

    it 're-saves the old answers if new answers not provided' do
      define_questions(domain: [
                         {
                           identifier: 'string_q',
                           question: 'String?',
                           default: 'This is the wrong string',
                         },
                         {
                           identifier: 'integer_q',
                           question: 'Integer?',
                           type: 'integer',
                           default: 10,
                         },
                         {
                           identifier: 'false_saved_boolean_q',
                           question: 'Boolean?',
                           type: 'boolean',
                           default: true,
                         },
                         {
                           identifier: 'true_saved_boolean_q',
                           question: 'More boolean?',
                           type: 'boolean',
                           default: false,
                         },
                         {
                           identifier: 'should_keep_old_answer',
                           question: 'Did I keep my old answer?',
                         },
                       ])

      original_answers = {
        string_q: 'CORRECT',
        integer_q: -100,
        false_saved_boolean_q: false,
        true_saved_boolean_q: true,
        should_keep_old_answer: 'old answer',
      }

      first_run_configure = nil
      redirect_stdout do
        first_run_configure = make_configurator
        first_run_configure.send(:save_answers, original_answers)
      end

      configure_with_answers([''] * 5)
      expect(answers).to eq(original_answers)
    end

    it 're-asks the required questions if no answer is given' do
      define_questions(domain: [
                         {
                           identifier: 'string_q',
                           question: 'I should be re-asked',
                         },
                       ])

      expect do
        old_stderr = STDERR
        begin
          $stderr = Tempfile.new
          STDERR = $stderr
          configure_with_answers([''] * 2)
        ensure
          STDERR = old_stderr
          $stderr = STDERR
        end
        # NOTE: EOFError occurs because HighLine is reading from an array of
        # end-line-characters. However as this is not a valid input it keeps
        # re-asking until it reaches the end and throws EOFError
      end.to raise_error(EOFError)

      output.rewind
      # Checks it was re-asked twice.
      # The '?' is printed when the question is re-asked
      expect(output.read.scan(/\?/).count).to eq(2)
    end

    it 're-prompts for answer to boolean questions until valid answer given' do
      define_questions(domain: [
                         {
                           identifier: 'boolean_q',
                           type: 'boolean',
                           question: 'Boolean question',
                         },
                       ])

      configure_with_answers(['foo', 'yes'])

      # Should be `true` (from the `yes`) rather than `false`, which 'foo' was
      # previously accepted and interpreted as.
      expect(answers).to eq(boolean_q: true)
    end

    it 'allows optional questions to have empty answers' do
      define_questions(domain: [
                         {
                           identifier: 'string_q',
                           question: 'I should NOT be re-asked',
                           optional: true,
                         },
                       ])
      expected = {
        string_q: '',
      }

      configure_with_answers([''])
      expect(answers).to eq(expected)
    end

    it 'indicates how far through questions you are' do
      define_questions(domain: [
                         {
                           identifier: 'question_1',
                           question: 'String question',
                         },
                         {
                           identifier: 'question_2',
                           question: 'Integer question',
                           type: 'integer',
                         },
                         {
                           identifier: 'question_3',
                           # The trailing spaces to test these are stripped.
                           question: '  Boolean question  ',
                           type: 'boolean',
                         },
                       ])

      configure_with_answers(['foo', 1, 'yes'])

      output.rewind
      output_lines = output.read.split("\n")
      [
        'String question (1/3)',
        'Integer question (2/3)',
        'Boolean question (3/3) [yes/no]',
      ].map do |question|
        expect(output_lines).to include(question)
      end
    end

    context 'when answers passed to configure' do
      it 'uses given answers instead of asking questions' do
        define_questions(domain: [
                           {
                             identifier: 'question_1',
                             question: 'Some question',
                           },
                         ])
        passed_answers = {
          question_1: 'answer_1',
        }

        configurator.configure(passed_answers)

        expect(answers).to eq(passed_answers)
      end
    end
  end

  context 'with an orphan node' do
    let(:orphan) { 'i_am_a_orphan_node' }
    let(:configure_orphan) { described_class.for_node(alces, orphan) }

    def new_group_cache
      Metalware::GroupCache.new
    end

    before do
      define_questions(node: [
                         {
                           identifier: 'string_q',
                           question: 'String?',
                           default: 'default',
                         },
                       ])
      configure_with_answers(['answer', 'sagh'], test_obj: configure_orphan)
    end

    it 'creates the orphan node' do
      expect(new_group_cache.orphans).to include(orphan)
    end
  end

  context 'with a dependent questions' do
    before do
      define_questions(domain: [
                         {
                           identifier: 'parent',
                           question: 'Ask my child?',
                           type: 'boolean',
                           dependent: [
                             {
                               identifier: 'child',
                               question: 'Did I get asked?',
                               type: 'boolean',
                             },
                           ],
                         },
                       ])
    end

    it 'asks the child if the parent is true' do
      configure_with_answers(['yes', 'yes'])
      expect(answers[:child]).to be(true)
    end

    it 'skips the child if the parent is false' do
      configure_with_answers(['no', 'yes'])
      expect(answers[:child]).to be(nil)
    end
  end

  context 'with existing domain level answer' do
    let(:original_default) { 'original-default-answer' }
    let(:group_name) { 'my-super-awesome-group' }
    let(:group_default) { 'I am the group level yaml default' }
    let(:node_default) { 'I am the node level yaml default' }
    let(:local_default) { 'I am the local level yaml default' }
    let(:domain_answer) { 'Domain answer with ERB, <%= node.name %>' }
    let(:identifier) { :question_identifier }
    let(:question) do
      {
        identifier: identifier.to_s,
        question: 'Where was my question set?',
      }
    end

    AlcesUtils.mock self, :each do
      mock_group(group_name)
      define_questions(
        domain: [question.merge(default: original_default)],
        group: [question.merge(default: group_default)],
        node: [question.merge(default: node_default)],
        local: [question.merge(default: local_default)]
      )
      configure_with_answers([domain_answer])
    end

    def configure_group(answer_input: answer)
      conf = Metalware::Configurator.for_group(alces, group_name)
      configure_with_answers([answer_input], test_obj: conf)
    end

    shared_examples 'gets the answer' do
      it { is_expected.to eq(answer) }

      it 'has saved the correct answer' do
        expect(load_answer).to eq(saved_answer)
      end
    end

    context 'when configuring a group' do
      subject do
        alces.groups.find_by_name(group_name).answer.to_h[identifier]
      end

      before { configure_group }

      let(:load_answer) do
        path = Metalware::FilePath.group_answers(group_name)
        Metalware::Data.load(path)[identifier]
      end

      context 'when the answer matches the original default' do
        let(:answer) { original_default }
        let(:saved_answer) { original_default }

        include_examples 'gets the answer'
      end

      context 'when the answer matches the domain answer' do
        let(:answer) { domain_answer }
        let(:saved_answer) { nil }

        include_examples 'gets the answer'
      end

      # NOTE: The group level default should be ignored Thus Configurator
      # should behave as if it is any other random input
      context 'when the answer matches the group level default' do
        let(:answer) { group_default }
        let(:saved_answer) { group_default }

        include_examples 'gets the answer'
      end

      context 'when the new answer matches a previously saved answer' do
        before { configure_group }
        let(:answer) { 'Some random answer' }
        let(:saved_answer) { answer }

        include_examples 'gets the answer'
      end
    end

    context 'when configuring a node' do
      subject do
        alces.nodes.find_by_name(node_name).answer.to_h[identifier]
      end

      let(:node_name) { 'my_super_awesome_node' }
      let(:group_answer) { 'I am the group level answer' }

      let(:load_answer) do
        path = Metalware::FilePath.node_answers(node_name)
        Metalware::Data.load(path)[identifier]
      end

      AlcesUtils.mock self, :each do
        configure_group(answer_input: group_answer)
        mock_node(node_name, group_name)
      end

      before do
        conf = described_class.for_node(alces, node_name)
        configure_with_answers([answer], test_obj: conf)
      end

      # The node yaml default should be ignored and saved like any other
      # answer
      context 'when the answer matches the node level default' do
        let(:answer) { node_default }
        let(:saved_answer) { node_default }

        include_examples 'gets the answer'
      end

      context 'when the answer matches the group level' do
        let(:answer) { group_answer }
        let(:saved_answer) { nil }

        include_examples 'gets the answer'
      end
    end

    context 'when configuring the local node' do
      subject do
        alces.local.answer.to_h[identifier]
      end

      let(:load_answer) do
        path = Metalware::FilePath.local_answers
        Metalware::Data.load(path)[identifier]
      end

      before do
        conf = described_class.for_local(alces)
        configure_with_answers([answer], test_obj: conf)
      end

      context 'when the answer matches the domain default' do
        let(:answer) { domain_answer }
        let(:saved_answer) { nil }

        include_examples 'gets the answer'
      end

      # The local yaml defaults should be ignored and thus treated like
      # any other answer
      context 'when the answer matches the local level default' do
        let(:answer) { local_default }
        let(:saved_answer) { local_default }

        include_examples 'gets the answer'
      end
    end
  end
end
