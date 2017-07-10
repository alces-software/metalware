
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
    YAML.load_file(answers_file_path)
  }

  let :configurator {
    make_configurator
  }

  def make_configurator(hl = highline)
    Metalware::Configurator.new(
      highline: hl,
      configure_file: configure_file_path,
      questions_section: 'test',
      answers_file: answers_file_path
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

      expect(highline).to receive(
        :ask
      ).with(
        'Can you enter a string?'
      ).and_return(
        'My string'
      )

      configurator.configure

      expect(answers).to eq({
        'string_q' => 'My string'
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

      expect(highline).to receive(
        :ask
      ).with(
        'Can you enter a string?'
      ).and_return(
        'My string'
      )

      configurator.configure

      expect(answers).to eq({
        'string_q' => 'My string'
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

      expect(highline).to receive(
        :ask
      ).with(
        'Can you enter an integer?', Integer
      ).and_return(
        7
      )

      configurator.configure

      expect(answers).to eq({
        'integer_q' => 7
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
       'Should this cluster be awesome?'
      ).and_return(
        true
      )

      configurator.configure

      expect(answers).to eq({
        'boolean_q' => true
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
      ).and_return(
        'bar'
      )

      configurator.configure

      expect(answers).to eq({
        'choice_q' => 'bar'
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

      allow(highline).to receive(
        :ask
      ).and_return('Some string', 11)
      allow(highline).to receive(
        :agree
      ).and_return(false)

      configurator.configure

      expect(answers).to eq(
        'string_q' => 'Some string',
        'integer_q' => 11,
        'boolean_q' => false,
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
          }
        }
      })

      configure_with_input("\n\n\n\n\n")

      expect(answers).to eq({
        'string_q' => str_ans,
        'string_erb' => erb_ans,
        'integer_q' => 10
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
          }
        }
      })

      old_answers = {
        "string_q" => "CORRECT",
        "integer_q" => -100,
        "should_not_see_me" => "OHHH SNAP"
      }
      new_answers = old_answers.dup.tap { |h| h.delete("should_not_see_me") }

      first_run_configure = nil
      redirect_stdout do
        first_run_configure = make_configurator(HighLine.new)
        first_run_configure.send(:save_answers, old_answers)
      end
      expect(first_run_configure.send(:old_answers)).to eq(old_answers)

      configure_with_input("\n\n\n\n\n\n")
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
          configure_with_input("\n")
        ensure
          STDERR = old_stderr
          $stderr = STDERR
        end
      }.to raise_error(EOFError)
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
        "string_q" => ""
      }

      configure_with_input("\n")
      expect(answers).to eq(expected)
    end
  end
end
