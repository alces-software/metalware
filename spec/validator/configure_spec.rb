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
require 'validator/configure.rb'
require 'utils'

RSpec.describe Metalware::Validator::Configure do
  let :correct_hash {
    {
      questions: {
        questions: "Are not part of the specification of a correct file.",
        note: "However they are very commonly associated with configure files"
      },

      domain: {
        string_question: {
          question: "Am I a string question without a default and type?"
        }
      },

      group: {
        string_question: {
          question: "Am I a string question without a type but with a default?",
          default: "yes I am a string"
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
    allow(Metalware::Utils).to receive(:safely_load_yaml).and_return(my_hash)
    Metalware::Validator::Configure.new("this/path/has/been/mocked").valid?
  end

  context 'with a valid input' do
    it 'passes with questions key' do
      expect(run_configure_validation(correct_hash)).to eq(true)
    end

    it 'passes without questions key' do
      correct_hash.delete(:questions)
      expect(run_configure_validation(correct_hash)).to eq(true)
    end
  end

  context 'with general invalid inputs' do
    it 'fails with invalid top level keys' do
      h = correct_hash.merge({
        invalid_key: true
      })
      expect(run_configure_validation(h)).to eq(false)
    end
  end

  context 'with invalid string inputs' do
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
        domain: {
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
end