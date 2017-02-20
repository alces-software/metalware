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
require "erb"
require "ostruct"

module Alces
  module Stack
    module Templater
      class << self
        def file(filename, template_parameters={})
          File.open(filename.chomp, 'r') do |file|
            return replace_hash(file.read, template_parameters)
          end
        end

        def save(template_file, save_file, template_parameters={})
          results = file(template_file, template_parameters)
          File.open(save_file.chomp, "w") do |f|
            f.puts(results)
          end
        end

        def append(template_file, append_file, template_parameters={})
          results = file(template_file, template_parameters)
          File.open(append_file.chomp, 'a') do |f|
            f.puts results
          end
        end

        def replace_hash(template, template_parameters={})
          return ERB.new(template).result(OpenStruct.new(template_parameters).instance_eval {binding})
        end

        def show_options(options={})
          puts "The following parameters are replaced by ERB:"
          options.each do |key, value|
            puts "    <%= #{key} %> : #{value}"
          end
          puts
        end
      end
    end
  end
end