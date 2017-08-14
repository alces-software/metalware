
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
require 'pathname'
require 'system_command'
require 'templating/repo_config_parser'
require 'templater'
require 'exceptions'

module Metalware
  module DNS
    class Named
      def initialize(metalware_config)
        @config = metalware_config
      end

      def update
        setup unless setup?
      end

      private

      attr_reader :config

      def file_path
        @file_path ||= FilePath.new(config)
      end

      def setup
        check_external_dns_is_set
        render_base_named_conf
      end

      def setup?
        SystemCommand.run_raw('systemctl status named')[:status] == 0
      end

      EXTERNAL_DNS_MSG = <<~EOF.strip_heredoc
        Can not setup `named` as `externaldns` has not been set in the domain.yaml
        repo config.
      EOF

      def check_external_dns_is_set
        raise MissingExternalDNS, EXTERNAL_DNS_MSG unless repo_config[:externaldns]
      end

      def repo_config
        Templating::RepoConfigParser
          .parse_for_domain(config: config, include_groups: false).inspect
      end

      def render_base_named_conf
        Templater.render_to_file(config, file_path.named_template, file_path.base_named)
      end
    end
  end
end
