#==============================================================================
# Copyright (C) 2007-2015 Stephen F. Norledge and Alces Software Ltd.
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
require 'yaml'
require 'alces/tools/cli'
require 'alces/tools/config'
require 'alces/stack'

module Alces
  module Stack
    module Config
      class CLI
        VALID_OUTPUT_TYPES = ['BASH']
        VALID_ACTIONS = ['SHOW']
        
        include Alces::Tools::CLI
        include Alces::Tools::Config
        
        root_only
        name 'alces-config'
        description 'Configuration file management'
        log_to File.join(Alces::Stack.config.log_root,'alces-config.log')

        option :type,
               description: "Specify output type #{VALID_OUTPUT_TYPES}",
               short: '-t',
               long: '--type',
               default: 'BASH',
               included_in: VALID_OUTPUT_TYPES

        option :action,
               description: "Specify an action to perform #{VALID_ACTIONS}",
               short: '-a',
               long: '--action',
               default: 'SHOW',
               required: true,
               included_in: VALID_ACTIONS

        option :name,
               description: "Specify configuration file name",
               short: '-n',
               long: '--name',
               required: true

        option :prefix,
               description: "Specify an output prefix",
               short: '-p',
               long: '--prefix'

        option :suffix,
               description: "Specify an output suffix",
               short: '-s',
               long: '--suffix'

        option :filter,
               description: "Regular expression to filter variables",
               short: '-f',
               long: '--filter'

        flag :upcase,
             'Upcase output variable names',
             '--upcase'
        
        class << self
          def config
            begin
              f = Alces::Tools::Config.find('alces-config.yml')
              @config = (if f.nil?
                           {}
                         else
                           YAML.load_file(f).tap do |cfg|
                             raise unless cfg.kind_of? Hash
                           end
                         end)
            rescue
              raise ConfigFileException, "Problem loading configuration file - #{f}"
            end
          end
        end

        def execute
          case action
          when /SHOW/i
            do_show
          else
            raise "Unable to determine action"
          end
        end

        def do_show
          f = Alces::Tools::Config.find(name, false)
          raise "Unable to find config file: #{name}" if f.nil?
          pfx = "#{prefix}_" unless prefix.nil?
          sfx = "_#{suffix}" unless suffix.nil?
          matcher = Regexp.new(filter) unless filter.nil?
          cfg = YAML.load_file(f)
          cfg.each do |k,v|
            next unless matcher.nil? || k =~ matcher
            varname = "#{pfx}#{k}#{sfx}"
            varname.upcase! if upcase
            puts "#{varname}='#{v.gsub("'","\\'")}'"
          end
        end
      end
    end
  end
end
