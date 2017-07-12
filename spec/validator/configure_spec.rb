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
require 'validator/configure'
require 'data'

RSpec.describe Metalware::Validator::Configure do
  let :correct_hash {
    {
      questions: {
        questions: "Are not part of the specification of a correct file.",
        note: "However they are very commonly associated with configure files",
        note2: "All other top level keys apart from questions, domain, group" \
               "and node will cause an error."
      },

      domain: {
        string_question: {
          question: "Am I a string question without a default and type?"
        },
        integer_question: {
          question: "Am I an integer question with a default?",
          type: "integer",
          default: 10
        }
      },

      group: {
        string_question: {
          question: "Am I a string question without a type but with a default?",
          default: "yes I am a string"
        },
        integer_question: {
          question: "Am I a integer question without a default?",
          type: "integer"
        }
      },

      node: {
        string_question: {
          question: "Am I a string question with a type and default?",
          type: "string",
          default: "yes I am a string"
        }
      }
    }
  }

  def run_configure_validation(my_hash = {})
    allow(Metalware::Data).to receive(:load).and_return(my_hash)
    validator = Metalware::Validator::Configure.new("path/has/been/mocked")
    validator.validate.messages
  end

  context 'with a valid input' do
    it 'passes with questions key' do
      expect(run_configure_validation(correct_hash)).to be_empty
    end

    it 'passes without questions key' do
      correct_hash.delete(:questions)
      expect(run_configure_validation(correct_hash)).to be_empty
    end

    it 'checks that deep merged hashes pass (tests the testing)' do
      h = correct_hash.deep_merge({
        domain: {
          check_string_question: {
            question: "Am I deep merged into the domain?",
            default: "I sure hope so"
          }
        }
      })
      expect(run_configure_validation(h)).to be_empty
    end
  end

  context 'with general invalid inputs' do
    it 'fails with invalid top level keys' do
      h = correct_hash.deep_merge({
        invalid_key: true
      })
      expect(run_configure_validation(h).keys).to eq([:valid_top_level_keys])
    end

    it 'fails if question is not a hash' do
      h = correct_hash.deep_merge({
        group: {
          question: "Am I missing my mid level question key?",
          type: "string",
          default: "Each field will now be interpreted as a separate question"
        }
      })
      results = run_configure_validation(h)
      expect(results.keys).to eq([:parameters])
      expect(results[:parameters][0]).to eq("must be a hash")
    end
  end

  context 'with invalid question fields' do
    it 'fails if unrecognized fields in a question' do
      h = correct_hash.deep_merge({
        domain: {
          invalid_field_question: {
            question: "Do I have have an unrecognized field?",
            default: "I do",
            invalid_filed: true
          }
        }
      })
      expect(run_configure_validation(h).keys).to eq([:valid_top_level_question_keys])
    end

    it 'fails if question is missing a title' do
      h = correct_hash.deep_merge({
        domain: { 
          missing_title_question: {
            default: "I am missing my question!"
          }
        }
      })
      results = run_configure_validation(h)
      expect(results[:parameters][:question][0]).to eq("is missing")
    end

    it 'fails if question if the title is empty' do
      h = correct_hash.deep_merge({
        node: { 
          missing_title_question: {
            question: "",
            default: "I am missing my question!"
          }
        }
      })
      results = run_configure_validation(h)
      expect(results[:parameters][:question][0]).to eq("must be filled")
    end

    it "fails if type isn't supported" do
      h = correct_hash.deep_merge({
        group: {
          unsupported_type: {
            question: "Do I have an unsupported type?",
            type: "Unsupported"
          }
        }
      })
      results = run_configure_validation(h)
      expect(results[:parameters].keys).to eq([:type])
    end

    it 'fails if default is empty' do
      h = correct_hash.deep_merge({
        domain: {
          empty_default: {
            question: "Do I have an empty default?",
            default: ""
          }
        }
      })
      results = run_configure_validation(h)
      expect(results[:parameters].keys).to eq([:default])
    end

    it 'fails if the optional input is not true or false' do
      h = correct_hash.deep_merge({
        group: {
          invalid_optional_flag: {
            question: "Do I have a boolean optional input?",
            optional: "I should be true or false"
          }
        }
      })
      results = run_configure_validation(h)
      expect(results[:parameters].keys).to eq([:optional])
    end
  end

  context 'with missing question blocks' do
    it 'fails when domain is missing' do
      correct_hash.delete(:domain)
      expect(run_configure_validation(correct_hash)).not_to be_empty
    end

    it 'fails when group is missing' do
      correct_hash.delete(:group)
      expect(run_configure_validation(correct_hash)).not_to be_empty
    end

    it 'fails when node is missing' do
      correct_hash.delete(:node)
      expect(run_configure_validation(correct_hash)).not_to be_empty
    end
  end

=begin
  context 'with invalid string questions' do
    it 'fails with a non-string default with no type specified' do
      h = correct_hash.deep_merge({
        domain: {
          bad_string_question: {
            question: "Do I fail because my default isn't a string?",
            default: 10
          }
        }
      })
      expect(run_configure_validation(h)).to eq(false)
    end

    it 'fails with a non-string default with a type specified' do
      h = correct_hash.deep_merge({
        group: {
          bad_string_question: {
            question: "Do I fail because my default isn't a string?",
            type: "string",
            default: 10
          }
        }
      })
      expect(run_configure_validation(h)).to eq(false)
    end
  end

=begin
  context 'with invalid integer questions' do
    it 'fails with non-integer default' do
      h = correct_hash.deep_merge({
        node: {
          bad_integer_question: {
            question: "Do I fail because my default is a string?",
            type: "integer",
            default: "10"
          }
        }
      })
      expect(run_configure_validation(h)).to eq(false)
    end
  end
=end
end