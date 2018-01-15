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

require 'validation/loader'

RSpec.describe Metalware::Validation::Loader do
  describe '#configure_data' do
    let! :config do
      # Need to create and cache a config before each test as this is expected
      # by FilePath.
      Metalware::Config.cache = Metalware::Config.new
    end

    let :configure_sections do
      Metalware::Constants::CONFIGURE_SECTIONS
    end

    let :configure_questions_hash do
      configure_sections.map do |section|
        [
          section, [{
            identifier: "#{section}_identifier",
            question: "#{section}_question",
          }]
        ]
      end.to_h
    end

    let :filesystem do
      FileSystem.setup do |fs|
        fs.dump(Metalware::FilePath.configure_file, configure_questions_hash)
      end
    end

    subject do
      described_class.new(config)
    end

    after :each do
      Metalware::Config.clear_cache
    end

    context 'when no plugins enabled' do
      it 'loads repo configure.yaml questions for all sections' do
        filesystem.test do
          sections_to_loaded_questions = configure_sections.map do |section|
            [section, subject.configure_data[section].children.map(&:content).map(&:to_h)]
          end.to_h

          configure_sections.each do |section|
            questions = sections_to_loaded_questions[section]
            question_identifiers = questions.map { |q| q[:identifier] }
            expect(question_identifiers).to eq ["#{section}_identifier"]
          end
        end
      end
    end
  end
end
