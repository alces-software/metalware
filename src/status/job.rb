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
require 'metal_log'
require 'timeout'
require 'constants'

module Metalware
  module Status
    class Job
      class << self
        def report_data(nodename, cmd, data)
          @results ||= {}
          @results[nodename] ||= {}
          @results[nodename][cmd] = data
        end

        attr_reader :results
      end

      def initialize(nodename, cmd, time_limit = 10)
        @nodename = nodename
        @cmd = cmd
        @time_limit = time_limit
        @status_log = MetalLog.new('status')
      end

      attr_reader :thread

      def start
        @thread = Thread.new do
          begin
            @status_log.info "Job Thread: #{Thread.current}"
            run_command
          rescue StandardError => e
            @status_log.fatal "JOB #{Thread.current}: #{e.inspect}"
          end
        end
        self
      end

      # ----- THREAD METHODS BELOW THIS LINE ------
      CMD_LIBRARY = {
        power: :job_power_status,
        ping: :job_ping_node,
      }.freeze

      def run_command
        Timeout.timeout(@time_limit) do
          @data = send(CMD_LIBRARY[@cmd] ? CMD_LIBRARY[@cmd] : @cmd)
        end
      rescue Timeout::Error
        @data = 'timeout'
      ensure
        kill_bash_process if @bash_pid
        self.class.report_data(@nodename, @cmd, @data)
      end

      def kill_bash_process
        Timeout.timeout(10) { _send_signal_and_wait(2) }
      rescue Timeout::Error
        _send_signal_and_wait(9)
      rescue Errno::ESRCH
      end

      def _send_signal_and_wait(signum)
        Process.kill signum, @bash_pid
        Process.wait(@bash_pid)
      end

      def run_bash(cmd)
        pipe = IO.popen(cmd)
        @bash_pid = pipe.pid
        pipe.read
      end

      def job_power_status
        script = File.join(Constants::METALWARE_INSTALL_PATH, 'libexec/power')
        cmd = "#{script} #{@nodename} status 2>&1"
        result = run_bash(cmd)
                 .scan(/Chassis Power is .*\Z/)[0].to_s
                 .scan(Regexp.union(/on/, /off/))[0]
        result.nil? ? 'error' : result
      end

      def job_ping_node
        cmd = "ping -c 1 #{@nodename} >/dev/null 2>&1; echo $?"
        result = run_bash(cmd)
        result.chomp == '0' ? 'ok' : 'error'
      end
    end
  end
end
