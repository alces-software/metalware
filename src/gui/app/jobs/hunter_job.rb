# frozen_string_literal: true

class HunterJob < ApplicationJob
  class << self
    attr_accessor :current_thread

    def hunting?
      current_thread&.alive?
    end
  end

  # XXX Somewhat similar to `BuildJob#perform`.
  def perform
    # Only want single `hunter` command running at once.
    return if self.class.hunting?

    self.class.current_thread = Thread.new do
      begin
        run_hunter_command
      rescue IntentionallyCatchAnyException => e
        # XXX Better error handling
        p 'ERROR', e
      end
    end
  end

  private

  def run_hunter_command
    Metalware::Utils.run_command(Metalware::Commands::Hunter)
  end
end
