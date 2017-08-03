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

require 'yaml'
require 'active_support/core_ext/hash/keys'

require 'constants'
require 'exceptions'
require 'ostruct'
require 'metal_log'
require 'validator/loader'
require 'validator/saver'
require 'file_path'

module Metalware
  class Config
    # XXX DRY these paths up.
    # XXX Maybe move all these paths into Constants and then reference them here
    KEYS_WITH_DEFAULTS = {
      build_poll_sleep: 10,
      answer_files_path: '/var/lib/metalware/answers',
      built_nodes_storage_path: '/var/lib/metalware/cache/built-nodes',
      rendered_files_path: '/var/lib/metalware/rendered',
      pxelinux_cfg_path: '/var/lib/tftpboot/pxelinux.cfg',
      repo_path: '/var/lib/metalware/repo',
      log_path: '/var/log/metalware',
      log_severity: 'INFO',
    }.freeze

    attr_reader :cli

    def initialize(file = nil, options = {})
      file ||= Constants::DEFAULT_CONFIG_PATH
      unless File.file?(file)
        raise MetalwareError, "Config file '#{file}' does not exist"
      end

      @config = Data.load(file)
      @cli = OpenStruct.new(options)
      MetalLog.reset_log(self)
    end

    KEYS_WITH_DEFAULTS.each do |key, default|
      define_method :"#{key}" do
        @config[key] || default
      end
    end

    def loader
      @loader ||= Validator::Loader.new(self)
    end

    def saver
      @saver ||= Validator::Saver.new(self)
    end

    def file_path
      @file_path ||= FilePath.new(self)
    end

    def repo_config_path(config_name)
      config_file = config_name + '.yaml'
      File.join(repo_path, 'config', config_file)
    end

    # TODO: Remove these methods as answer files should always be loaded through
    # the Loader so they can be validated. If for some reason the path is
    # required, then the path can be accessed from the FilePath class
    def configure_file
      File.join(repo_path, 'configure.yaml')
    end

    def domain_answers_file
      File.join(answer_files_path, 'domain.yaml')
    end

    def group_answers_file(group_name)
      file_name = "#{group_name}.yaml"
      File.join(answer_files_path, 'groups', file_name)
    end

    def node_answers_file(node_name)
      file_name = "#{node_name}.yaml"
      File.join(answer_files_path, 'nodes', file_name)
    end
  end
end
