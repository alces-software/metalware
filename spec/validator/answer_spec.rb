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
require 'validator/answer'
require 'data'
require 'config'

RSpec.describe Metalware::Validator::Answer do
  let :config do
    Metalware::Config.new
  end

  let :correct_hash do
    {
      answer: {
        string_question: 'string',
        integer_question: 100,
        bool_question: true,
      },

      configure: {
        domain: {
          string_question: {
            question: 'Am I a string?',
          },
          integer_question: {
            question: 'Am I a integer',
            type: 'integer',
          },
          bool_question: {
            question: 'Am I a boolean',
            type: 'boolean',
          },
        },
      },
    }
  end

  def run_answer_validation(my_hash = {})
    allow(Metalware::Data).to receive(:load).and_return(
      {}, my_hash[:answer], correct_hash[:configure]
    )
    validator = Metalware::Validator::Answer.new(config, 'domain.yaml')
    validator.validate
  end

  def get_question_with_an_incorrect_type(results)
    expect(results.errors).not_to be_empty
    # ONLY supports results with a single error question
    expect(results.errors[:answers].keys.length).to eq(1)
    error_question_index = results.errors[:answers].keys[0]
    results.output[:answers][error_question_index]
  end

  context 'with a valid answer hash' do
    it 'returns successfully' do
      errors = run_answer_validation(correct_hash).errors
      expect(errors.keys).to be_empty
    end
  end

  context 'with an invalid answer hash' do
    it 'validates basic answer structure' do
      h = {
        answer: ['I', 'Am', 'Not', 'A', 'Hash'],
      }
      errors = run_answer_validation(h).errors
      expect(errors).to eq(answers: ['must be a hash'])
    end

    it 'contains an answer to a missing question' do
      h = {
        answer: {
          missing_question: 'I do not appear in configure.yaml',
        },
      }
      errors = run_answer_validation(h).errors
      expect(errors.keys).to include(:missing_questions)
    end

    it 'detects a question with the wrong type' do
      test_hash = correct_hash.tap do |h|
        h[:answer][:integer_question] = 'I should not be a string'
      end
      results = run_answer_validation(test_hash)
      error_question = get_question_with_an_incorrect_type(results)
      expect(error_question[:question]).to eq(:integer_question)
    end
  end
end
