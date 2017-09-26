# frozen_string_literal: true

class NodesController < ApplicationController
  METAL = Metalware::Constants::METAL_EXECUTABLE_PATH

  def power_reset
    # `metal power` currently works by `exec`ing a Bash script, so run this in
    # separate process rather than having the current Rails process be replaced
    # (which would be bad). It also doesn't give an indication (apart from by
    # parsing its output) of whether the command failed, e.g. a non-zero in
    # this case, so just display the output as a generic notice for now.
    # XXX Improve the power command and hence this action; running the command
    # can also be very slow so may be better way to run this than within single
    # HTTP request.
    command = "#{METAL} power #{node_name} reset"
    flash.notice = Metalware::SystemCommand.run(command)
    redirect_to '/'
  end
end
