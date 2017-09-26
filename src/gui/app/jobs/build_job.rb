# frozen_string_literal: true

class BuildJob < ApplicationJob
  THREADS = ThreadGroup.new

  class << self
    def find(identifier_value)
      THREADS.list.find do |thread|
        thread.thread_variable_get(self::IDENTIFIER) == identifier_value
      end
    end
  end

  def perform(identifier_value)
    return if self.class.find(identifier_value)

    build_thread = Thread.new do
      begin
        Thread.current.thread_variable_set(
          self.class::IDENTIFIER,
          identifier_value
        )
        run_build_command(identifier_value)
      rescue IntentionallyCatchAnyException => e
        Metalware::Output.error(e.message)
      end

      # Sleep forever (until thread is killed); current thread no longer needs
      # to do anything, just need to keep around messages.
      sleep
    end

    THREADS.add(build_thread)
  end

  private

  def run_build_command(_identifier_value)
    raise NotImplementedError
  end
end
