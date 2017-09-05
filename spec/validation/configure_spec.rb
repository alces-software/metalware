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

require 'config'
require 'validation/configure'
require 'file_path'
require 'data'
require 'filesystem'

RSpec.describe Metalware::Validation::Configure do
  let :config { Metalware::Config.new }
  let :file_path { Metalware::FilePath.new(config) }

  let :correct_hash do
    {
      questions: {
        questions: 'Are not part of the specification of a correct file.',
        note: 'However they are very commonly associated with configure files',
        note2: 'All other top level keys apart from questions, domain, group' \
               'and node will cause an error.',
      },

      domain: [
        {
          identifier: 'string_question',
          question: 'Am I a string question without a default and type?',
        },
        {
          identifier: 'integer_question',
          question: 'Am I an integer question with a default?',
          type: 'integer',
          default: 10,
        },
        {
          identifier: 'boolean_true',
          question: 'Can I have a boolean true (/yes) default?',
          type: 'boolean',
          default: 'yes',
        },
      ],

      group: [
        {
          identifier: 'string_question',
          question: 'Am I a string question without a type but with a default?',
          default: 'yes I am a string',
        },
        {
          identifier: 'integer_question',
          question: 'Am I a integer question without a default?',
          type: 'integer',
        },
        {
          identifier: 'boolean_false',
          question: 'Can I have a boolean false (/no) default?',
          type: 'boolean',
          default: 'no',
        },
      ],

      node: [
        {
          identifier: 'string_question',
          question: 'Am I a string question with a type and default?',
          type: 'string',
          default: 'yes I am a string',
        },
        {
          identifier: 'string_empty_default',
          question: 'My default is a empty string?',
          default: '',
        },
      ],

      self: [],
    }
  end

  context 'without a hash input' do
    it 'loads configure file from the repo' do
      data = { data: 'I am the configure data' }
      Metalware::Data.dump(file_path.configure_file, data)
      v = Metalware::Validation::Configure.new(config)
      expect(v.send(:raw_data)).to eq(data)
    end
  end

  context 'with a hash input' do
    it 'uses the has as the data input' do
      v = Metalware::Validation::Configure.new(config, correct_hash)
      expect(v.send(:raw_data)).to eq(correct_hash)
    end
  end

  def run_configure_validation(my_hash = {})
    Metalware::Validation::Configure.new(config, my_hash).data
  end

  def expect_configure_error(my_hash, msg_regex)
    expect{
      run_configure_validation(my_hash)
    }.to raise_error(Metalware::ValidationFailure, msg_regex)
  end

  context 'with a valid input' do
    it 'passes with questions key' do
      expect(run_configure_validation(correct_hash)).to eq(correct_hash)
    end

    it 'passes without questions key' do
      correct_hash.delete(:questions)
      expect(run_configure_validation(correct_hash)).to eq(correct_hash)
    end
  end

  context 'with general invalid inputs' do
    it 'fails with invalid top level keys' do
      h = correct_hash.deep_merge(invalid_key: true)
      expect_configure_error(h, /invalid top level key/)
    end

    it 'fails if sections are not an array' do
      h = correct_hash.deep_merge(group: { key: 'I am not an array' })
      expect_configure_error(h, /must be an array/)
    end
  end

  context 'with invalid question fields' do
    it 'fails if the question is missing or empty identifier' do
      h = correct_hash.deep_merge(self: [{ question: 'I have no identifier' }])
      expect_configure_error(h, /is missing/)
      h = correct_hash.deep_merge(self: [{ 
        question: 'I have no identifier',
        identifier: '',
      }])
      expect_configure_error(h, /must be filled/)
    end


    it 'fails if question is missing or empty' do
      h = correct_hash.deep_merge(self: [{ identifier: 'missing_question' }])
      expect_configure_error(h, /is missing/)
      h = correct_hash.deep_merge(self: [{ 
        question: '',
        identifier: 'no_question',
      }])
      expect_configure_error(h, /must be filled/)
    end

    # it "fails if type isn't supported" do
    #   h = correct_hash.deep_merge(group: {
    #                                 unsupported_type: {
    #                                   question: 'Do I have an unsupported type?',
    #                                   type: 'Unsupported',
    #                                 },
    #                               })
    #   results = run_configure_validation(h)
    #   expect(results[:parameters].keys).to eq([:type])
    # end

    it 'fails if the optional input is not true or false' do
      h = correct_hash.deep_merge(group: [{
                                    identifier: 'invalid_optional_flag',
                                    question: 'Do I have a boolean optional input?',
                                    optional: 'I should be true or false',
                                  }])
      expect_configure_error(h, /must be boolean/)
    end
  end

  context 'with missing question blocks' do
    it 'fails when domain is missing' do
      correct_hash.delete(:domain)
      expect_configure_error(correct_hash, /is missing/)
    end

    it 'fails when group is missing' do
      correct_hash.delete(:group)
      expect_configure_error(correct_hash, /is missing/)
    end

    it 'fails when node is missing' do
      correct_hash.delete(:node)
      expect_configure_error(correct_hash, /is missing/)
    end

    it 'fails when self is missing' do
      correct_hash.delete(:self)
      expect_configure_error(correct_hash, /is missing/)
    end
  end

  # context 'with invalid string questions' do
  #   it 'fails with a non-string default with no type specified' do
  #     h = correct_hash.deep_merge(domain: {
  #                                   bad_string_question: {
  #                                     question: "Do I fail because my default isn't a string?",
  #                                     default: 10,
  #                                   },
  #                                 })
  #     expect(run_configure_validation(h).keys).to eq([:default_string_type])
  #   end

  #   it 'fails with a non-string default with a type specified' do
  #     h = correct_hash.deep_merge(group: {
  #                                   bad_string_question: {
  #                                     question: "Do I fail because my default isn't a string?",
  #                                     type: 'string',
  #                                     default: 10,
  #                                   },
  #                                 })
  #     expect(run_configure_validation(h).keys).to eq([:default_string_type])
  #   end

  #   it 'returns a success? status of false' do
  #     h = correct_hash.deep_merge(group: {
  #                                   bad_string_question: {
  #                                     question: "Do I fail because my default isn't a string?",
  #                                     type: 'string',
  #                                     default: 10,
  #                                   },
  #                                 })
  #     expect(build_validator(h).success?).to eq(false)
  #   end
  # end

  # context 'with invalid integer questions' do
  #   it 'fails with non-integer default' do
  #     h = correct_hash.deep_merge(node: {
  #                                   bad_integer_question: {
  #                                     question: 'Do I fail because my default is a string?',
  #                                     type: 'integer',
  #                                     default: '10',
  #                                   },
  #                                 })
  #     expect(run_configure_validation(h).keys).to eq([:default_integer_type])
  #   end
  # end

  # context 'with invalid boolean questions' do
  #   it 'fails with non-boolean default' do
  #     h = correct_hash.deep_merge(node: {
  #                                   bad_integer_question: {
  #                                     question: 'Do I fail because my default is a string?',
  #                                     type: 'boolean',
  #                                     default: 'I am not valid',
  #                                   },
  #                                 })
  #     expect(run_configure_validation(h).keys).to eq([:default_boolean_type])
  #   end
  # end
end
