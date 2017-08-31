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
      rescue Exception => e
        # XXX Better error handling
        p 'ERROR', e
      end
    end

    THREADS.add(build_thread)
  end

  private

  def run_build_command(_identifier_value)
    raise NotImplementedError
  end
end
