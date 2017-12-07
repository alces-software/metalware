# frozen_string_literal: true

module Metalware
  class BuildEvent
    def initialize(nodes)
      @nodes = nodes.dup
    end

    def run_start_hooks
      nodes.each { |node| run_hook(node, 'start') }
    end

    # TODO: Atm only the complete_hook is supported. Eventually this needs to
    # be expanded to other hooks
    def process
      nodes_complete
    end

    def build_complete?
      return false if hook_active?
      nodes.empty?
    end

    def hook_active?
      build_threads.delete_if { |th| !th.alive? }
                   .each(&:join)
      !build_threads.empty?
    end

    def kill_threads
      build_threads.each(&:kill)
      sleep 0.001 while hook_active?
    end

    private

    attr_reader :nodes

    def build_threads
      @build_threads ||= []
    end

    def nodes_complete
      nodes.delete_if do |node|
        next unless File.exist?(node.build_complete_path)
        run_hook(node, 'complete')
        FileUtils.rm node.build_complete_path
        true
      end
    end

    def run_hook(node, hook_name)
      build_threads.push(Thread.new do
        begin
          node.build_method.send("#{hook_name}_hook")
        rescue => e
          $stderr.puts e.message
          $stderr.puts e.backtrace
        end
      end)
    end
  end
end
