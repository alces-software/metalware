
require 'tempfile'
require 'yaml'
require 'highline'

require 'configurator'

RSpec.describe Metalware::Configurator do
  let :input {
    Tempfile.new
  }

  let :output {
    Tempfile.new
  }

  let :highline {
    HighLine.new(input, output)
  }

  let :configure_file {
    Tempfile.new('configure.yaml')
  }

  let :configure_file_path {
    configure_file.path
  }

  let :answers_file_path {
    Tempfile.new('test.yaml').path
  }

  let :answers {
    Metalware::Data.load(answers_file_path)
  }

  let :configurator {
    make_configurator
  }

  def make_configurator(hl = highline)
    Metalware::Configurator.new(
      highline: hl,
      configure_file: configure_file_path,
      questions_section: :test,
      answers_file: answers_file_path,
      # Do not want to use readline to get input in tests as tests will then
      # hang waiting for input.
      use_readline: false
    )
  end

  def define_questions(questions_hash)
    configure_file.write(questions_hash.to_yaml)
    configure_file.rewind
  end

  def redirect_stdout(&block)
    $stdout = tmp = Tempfile.new
    block.call
    tmp.close
  rescue => e
    begin
      $stdout.rewind
      STDERR.puts $stdout.read
    rescue
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
      define_questions({
        test: {
          string_q: {
            question: 'Can you enter a string?',
            type: 'string'
          }
        }
      })

      configure_with_answers(['My string'])

      expect(answers).to eq({
        string_q: 'My string'
      })
    end


    it 'asks questions with no `type` as `string`' do
      define_questions({
        test: {
          string_q: {
            question: 'Can you enter a string?'
          }
        }
      })

      configure_with_answers(['My string'])

      expect(answers).to eq({
        string_q: 'My string'
      })
    end

    it 'asks questions with type `integer`' do
      define_questions({
        test: {
          integer_q: {
            question: 'Can you enter an integer?',
            type: 'integer'
          }
        }
      })

      configure_with_answers(['7'])

      expect(answers).to eq({
        integer_q: 7
      })
    end

    it "uses confirmation for questions with type 'boolean'" do
      define_questions({
        test: {
          boolean_q: {
            question: 'Should this cluster be awesome?',
            type: 'boolean'
          }
        }
      })

      expect(highline).to receive(
        :agree
      ).with(
        # Note that an indication of what the input should be has been appended
        # to the asked question.
        'Should this cluster be awesome? [yes/no]'
      ).and_call_original

      configure_with_answers(['yes'])

      expect(answers).to eq({
        boolean_q: true
      })
    end

    it "offers choices for question with type 'choice'" do
      define_questions({
        test: {
          choice_q: {
            question: 'What choice would you like?',
            type: 'choice',
            choices: ['foo', 'bar']
          }
        }
      })

      expect(highline).to receive(
        :choose
      ).with(
        'foo', 'bar'
      ).and_call_original

      configure_with_answers(['bar'])

      expect(answers).to eq({
        choice_q: 'bar'
      })
    end

    it 'asks all questions in order' do
      define_questions({
        test: {
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
            question: 'Not asked?'
          }
        }
      })

      configure_with_answers(['Some string', '11', 'no'])

      expect(answers).to eq(
        string_q: 'Some string',
        integer_q: 11,
        boolean_q: false,
      )
    end

    it 'fails fast for question with unknown type' do
      define_questions({
        test: {
          # This question
          string_q: {
            question: 'String?',
            type: 'string',
          },
          unknown_q: {
            question: 'Something odd?',
            type: 'foobar',
          }
        },
      })

      expect {
        configurator.send(:questions)
      }.to raise_error(
        Metalware::UnknownQuestionTypeError,
        /'foobar'.*test\.unknown_q.*#{configure_file_path}/
      )
    end

    it 'loads default values' do

      str_ans = "I am a little teapot!!"
      erb_ans = '<%= I_am_an_erb_tag %>'

      define_questions({
        test: {
          string_q: {
            question: 'String?',
            type: 'string',
            default: str_ans
          },
          string_erb: {
            question: 'Erb?',
            default: erb_ans,
          },
          integer_q: {
            question: 'Integer?',
            type: 'integer',
            default: 10
          },
          true_boolean_q: {
            question: 'Boolean?',
            type: 'boolean',
            default: true
          },
          false_boolean_q: {
            question: 'More boolean?',
            type: 'boolean',
            default: false
          },
        }
      })

      configure_with_answers([''] * 5)

      expect(answers).to eq({
        string_q: str_ans,
        string_erb: erb_ans,
        integer_q: 10,
        true_boolean_q: true,
        false_boolean_q: false
      })
    end

    it 'loads the old answers as defaults' do
      define_questions({
        test: {
          string_q: {
            question: "String?",
            default: "This is the wrong string"
          },
          integer_q: {
            question: 'Integer?',
            type: 'integer',
            default: 10
          },
          false_saved_boolean_q: {
            question: 'Boolean?',
            type: 'boolean',
            default: true
          },
          true_saved_boolean_q: {
            question: 'More boolean?',
            type: 'boolean',
            default: false
          },
        }
      })

      old_answers = {
        string_q: "CORRECT",
        integer_q: -100,
        false_saved_boolean_q: false,
        true_saved_boolean_q: true,
        should_not_see_me: "OHHH SNAP",
      }
      new_answers = old_answers.dup.tap { |h| h.delete(:should_not_see_me) }

      first_run_configure = nil
      redirect_stdout do
        first_run_configure = make_configurator(HighLine.new)
        first_run_configure.send(:save_answers, old_answers)
      end
      expect(first_run_configure.send(:old_answers)).to eq(old_answers)

      configure_with_answers([''] * 4)
      expect(answers).to eq(new_answers)
    end

    it 're-asks the required questions if no answer is given' do
      define_questions({
        test: {
          string_q: {
            question: "I should be re-asked"
          }
        }
      })

      expect{
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
      }.to raise_error(EOFError)

      output.rewind
      # Checks it was re-asked twice.
      # The '?' is printed when the question is re-asked
      expect(output.read.scan(/\?/).count).to eq(2)
    end

    it 'allows optional questions to have empty answers' do
      define_questions({
        test: {
          string_q: {
            question: "I should NOT be re-asked",
            optional: true
          }
        }
      })
      expected = {
        string_q: ''
      }

      configure_with_answers([''])
      expect(answers).to eq(expected)
    end
  end
end
