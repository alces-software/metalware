# frozen_string_literal: true

class BuildNodeJob < ApplicationJob
  queue_as :default

  THREADS = ThreadGroup.new

  class << self
    def find(node_name)
      THREADS.list.find do |thread|
        thread.thread_variable_get(:node_name) == node_name
      end
    end
  end

  def perform(node_name)
    return if self.class.find(node_name)

    build_thread = Thread.new do
      Thread.current.thread_variable_set(:node_name, node_name)
      begin
        Metalware::Utils.run_command(Metalware::Commands::Build, node_name)
      rescue => e
        # XXX Better error handling
        p 'ERROR', e
      end
    end

    THREADS.add(build_thread)
  end
end
