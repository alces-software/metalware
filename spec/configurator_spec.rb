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

require 'config'
require 'configurator'
require 'validation/loader'

RSpec.describe Metalware::Configurator do
  let :input do
    Tempfile.new
  end

  let :output do
    Tempfile.new
  end

  let :highline do
    HighLine.new(input, output)
  end

  let :answers do
    loader.domain_answers
  end

  let :higher_level_answer_files { [] }

  let :config { Metalware::Config.new }
  let :loader { Metalware::Validation::Loader.new(config) }

  def define_higher_level_answer_files(answer_file_hashes)
    answer_file_hashes.map do |answers|
      Tempfile.new.path.tap { |path| Metalware::Data.dump(path, answers) }
    end
  end

  let :configurator do
    make_configurator
  end

  def make_configurator
    # Spoofs HighLine to always return the testing version of highline
    allow(HighLine).to receive(:new).and_return(highline)
    Metalware::Configurator.new(
      config: config,
      questions_section: :domain,
      higher_level_answer_files: higher_level_answer_files,
      # Do not want to use readline to get input in tests as tests will then
      # hang waiting for input.
      use_readline: false
    )
  end

  def define_questions(questions_hash)
    allow(loader).to receive(:configure_data).and_return(questions_hash)
    allow(Metalware::Validation::Loader).to receive(:new).and_return(loader)
  end

  def redirect_stdout
    $stdout = tmp = Tempfile.new
    yield
    tmp.close
  rescue => e
    begin
      $stdout.rewind
      STDERR.puts $stdout.read
    rescue
      # XXX Not handling this gives a Rubocop warning; should we do something
      # here?
    end
    raise e
  ensure
    $stdout = STDOUT
  end

  def configure_with_input(input_string)
    redirect_stdout do
      input.write(input_string)
      input.rewind
      configurator.configure
    end
  end

  def configure_with_answers(answers)
    # Each answer must be entered followed by a newline to terminate it.
    configure_with_input(answers.join("\n") + "\n")
  end

  describe '#configure' do
    it 'asks questions with type `string`' do
      define_questions(domain: {
                         string_q: {
                           question: 'Can you enter a string?',
                           type: 'string',
                         },
                       })

      configure_with_answers(['My string'])

      expect(answers).to eq(string_q: 'My string')
    end

    it 'asks questions with no `type` as `string`' do
      define_questions(domain: {
                         string_q: {
                           question: 'Can you enter a string?',
                         },
                       })

      configure_with_answers(['My string'])

      expect(answers).to eq(string_q: 'My string')
    end

    it 'asks questions with type `integer`' do
      define_questions(domain: {
                         integer_q: {
                           question: 'Can you enter an integer?',
                           type: 'integer',
                         },
                       })

      configure_with_answers(['7'])

      expect(answers).to eq(integer_q: 7)
    end

    it "uses confirmation for questions with type 'boolean'" do
      define_questions(domain: {
                         boolean_q: {
                           question: 'Should this cluster be awesome?',
                           type: 'boolean',
                         },
                       })

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
      define_questions(domain: {
                         choice_q: {
                           question: 'What choice would you like?',
                           choices: ['foo', 'bar'],
                         },
                       })

      expect(highline).to receive(
        :choose
      ).with(
        'foo', 'bar'
      ).and_call_original

      configure_with_answers(['bar'])

      expect(answers).to eq(choice_q: 'bar')
    end

    it 'asks all questions in order' do
      define_questions(domain: {
                         string_q: {
                           question: 'String?',
                           type: 'string',
                         },
                         integer_q: {
                           question: 'Integer?',
                           type: 'integer',
                         },
                         boolean_q: {
                           question: 'Boolean?',
                           type: 'boolean',
                         },
                       },
                       some_other_questions: {
                         not_asked_q: {
                           question: 'Not asked?',
                         },
                       })

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

      define_questions(domain: {
                         string_q: {
                           question: 'String?',
                           type: 'string',
                           default: str_ans,
                         },
                         string_erb: {
                           question: 'Erb?',
                           default: erb_ans,
                         },
                         integer_q: {
                           question: 'Integer?',
                           type: 'integer',
                           default: 10,
                         },
                         true_boolean_q: {
                           question: 'Boolean?',
                           type: 'boolean',
                           default: true,
                         },
                         false_boolean_q: {
                           question: 'More boolean?',
                           type: 'boolean',
                           default: false,
                         },
                       })

      configure_with_answers([''] * 5)

      expect(answers).to eq({})
    end

    it 're-saves the old answers if new answers not provided' do
      define_questions(domain: {
                         string_q: {
                           question: 'String?',
                           default: 'This is the wrong string',
                         },
                         integer_q: {
                           question: 'Integer?',
                           type: 'integer',
                           default: 10,
                         },
                         false_saved_boolean_q: {
                           question: 'Boolean?',
                           type: 'boolean',
                           default: true,
                         },
                         true_saved_boolean_q: {
                           question: 'More boolean?',
                           type: 'boolean',
                           default: false,
                         },
                         should_keep_old_answer: {
                           question: 'Did I keep my old answer?',
                         },
                       })

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
      expect(first_run_configure.send(:old_answers)).to eq(original_answers)

      configure_with_answers([''] * 5)
      expect(answers).to eq(original_answers)
    end

    context 'when higher level answer files provided' do
      let :higher_level_answer_files do
        define_higher_level_answer_files(
          [
            {
              top_level_q: 'top_level_q_answer',
              both_higher_levels_q: 'both_higher_levels_q_top_level_answer',
            },
            {
              overridden_default_q: 'higher_level_q_overriding_answer',
              both_higher_levels_q: 'both_higher_levels_q_higher_answer',
              higher_level_q: 'higher_level_q_answer',
            },
          ]
        )
      end

      before do
        define_questions(domain: {
                           default_q: {
                             question: 'default_q',
                             default: 'default_answer',
                           },
                           overridden_default_q: {
                             question: 'overridden_default_q',
                             default: 'default_answer',
                           },
                           top_level_q: { question: 'top_level_q' },
                           both_higher_levels_q: { question: 'both_higher_levels_q' },
                           higher_level_q: { question: 'higher_level_q' },
                         })
      end

      it 'saves nothing if no input given' do
        configure_with_answers([''] * 5)

        expect(answers).to eq({})
      end

      it 'uses the highest precedence answer for each question as the default' do
        configure_with_answers([''] * 5)

        output.rewind
        output_lines = output.read.split("\n")

        expected_defaults = [
          'default_answer',
          'higher_level_q_overriding_answer',
          'top_level_q_answer',
          'both_higher_levels_q_higher_answer',
          'higher_level_q_answer',
        ]

        output_lines.zip(expected_defaults).each do |output_line, expected_default|
          expect(output_line).to include("|#{expected_default}|")
        end
      end
    end

    context 'with boolean question answered at higher level' do
      let :higher_level_answer_files do
        define_higher_level_answer_files(
          [
            { false_boolean_q: false },
          ]
        )
      end

      it 'correctly inherits false default' do
        define_questions(domain: {
                           false_boolean_q: {
                             question: 'Boolean?',
                             type: 'boolean',
                           },
                         })

        configure_with_answers([''])

        output.rewind
        expect(output.read).to include('|no|')
      end
    end

    it 're-asks the required questions if no answer is given' do
      define_questions(domain: {
                         string_q: {
                           question: 'I should be re-asked',
                         },
                       })

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

    it 'allows optional questions to have empty answers' do
      define_questions(domain: {
                         string_q: {
                           question: 'I should NOT be re-asked',
                           optional: true,
                         },
                       })
      expected = {
        string_q: '',
      }

      configure_with_answers([''])
      expect(answers).to eq(expected)
    end

    it 'indicates how far through questions you are' do
      define_questions(domain: {
                         question_1: {
                           question: 'String question',
                         },
                         question_2: {
                           question: 'Integer question',
                           type: 'integer',
                         },
                         question_3: {
                           # This question has trailing spaces to test these are stripped.
                           question: '  Boolean question  ',
                           type: 'boolean',
                         },
                       })

      configure_with_answers(['foo', 1, true])

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
        define_questions(domain: {
                           question_1: {
                             question: 'Some question',
                           },
                         })
        passed_answers = {
          question_1: 'answer_1',
        }

        configurator.configure(passed_answers)

        expect(answers).to eq(passed_answers)
      end
    end
  end
end
