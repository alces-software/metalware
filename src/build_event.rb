# frozen_string_literal: true

module Metalware
  class BuildEvent
    def initialize(nodes)
      @nodes = nodes.dup
    end

    def run_start_hooks
      nodes.each { |node| run_hook { node.build_method.start_hook } }
    end

    # TODO: Atm only the complete_hook is supported. Eventually this needs to
    # be expanded to other hooks
    def process
      nodes.each do |node|
        node_complete(node)
      end
    end

    def build_complete?
      return false if hook_active?
      nodes.empty?
    end

    def hook_active?
      build_threads.delete_if { |th| !th.alive? }
      !build_threads.empty?
    end

    def kill_threads
      build_threads.each(&:kill)
    end

    private

    attr_reader :nodes

    def build_threads
      @build_threads ||= []
    end

    def node_complete(node)
      return unless File.exist?(node.build_complete_path)
      run_hook do
        node.build_method.complete_hook
      end
    end

    def run_hook
      build_threads.push(Thread.new do
        begin
          yield
        rescue
          $stderr.puts $ERROR_INFO.message
          $stderr.puts $ERROR_INFO.backtrace
        end
      end)
    end
  end
end
