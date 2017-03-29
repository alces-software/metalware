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
module Alces
  module Stack
    class Finder
      def initialize(default_repo, default_path_repo, template)
        @default_repo = default_repo.chomp("/")
        @default_path_repo = default_path_repo.chomp("/")
        @repo = get_repo(template)
        @template = find_template(template).chomp
        @filename_ext = File.basename(@template)
        @filename_ext_trim_erb = File.basename(@template, ".erb")
        @filename = File.basename(@template, ".*")
        @path = File.dirname(@template)
      end

      attr_reader :repo
      attr_reader :template
      attr_reader :filename
      attr_reader :filename_ext
      attr_reader :filename_ext_trim_erb
      attr_reader :path

      def filename_diff_ext(ext)
        ext = ".#{ext}" if ext[0] != "."
        return "#{@filename}#{ext}"
      end

      def get_repo(template_input)
        template = template_input.to_s
        raise ErrorRepoNotFound.new "(undefined)" unless template.scan(/\A::/).empty?
        repo_arr = template.scan(/\A.*::/)
        if repo_arr.length > 1
          raise ErrorRepoNotFound
        elsif repo_arr.length == 1
          repo = "/var/lib/metalware/repos/#{repo_arr[0].gsub("::", "")}"
        elsif @default_repo.empty? || !@default_repo
          repo = "/"
        else
          repo = @default_repo
        end
        raise ErrorRepoNotFound.new repo unless File.directory?(repo)
        return repo.chomp("/")
      end

      class ErrorRepoNotFound < StandardError
        def initialize (repo)
          msg = "Could not find repo: #{repo}"
          super msg
        end
      end

      def find_template(template)
        # Preprocessing
        t_hash = process_template(template)
        location = "#{@repo}/#{@default_path_repo}".gsub(/\/\/+/, "/")

        # Match tests
        match_arr = [method(:match_full_path_in_default),
                     method(:match_sub_path_in_default),
                     method(:match_full_path)]

        # Checks for a match
        match_arr.each do |match_test|
          result = match_test.call(location, t_hash)
          return result if result
        end

        raise TemplateNotFound.new(template)
      end

      def process_template(template)
        copy = "#{template}".gsub(/\A.*::/, "").gsub(/\/\/+/, "/")
        h = {
          t: "#{copy}",
          e: "#{copy}.erb"
        }
      end

      def match_full_path_in_default(location, template = {})
        return nil unless template[:t] == /\A#{location}.*\Z/
        return template[:t] if File.file?(template[:t])
        return template[:e] if File.file?(template[:e])
        return nil
      end

      def match_sub_path_in_default(location, template = {})
        copy = {}
        copy[:t] = "#{location}/#{template[:t]}".gsub(/\/\/+/, "/")
        copy[:e] = "#{location}/#{template[:e]}".gsub(/\/\/+/, "/")
        return copy[:t] if File.file?(copy[:t])
        return copy[:e] if File.file?(copy[:e])
        return nil
      end

      def match_full_path(location, template = {})
        return template[:t] if File.file?(template[:t])
        return template[:e] if File.file?(template[:e])
        return nil
      end

      class TemplateNotFound < StandardError
        def intialize(template)
          msg = "Could not find template file: " << template
          super
        end
      end
    end
  end
end