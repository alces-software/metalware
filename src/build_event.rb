# frozen_string_literal: true

module Metalware
  class BuildEvent
    def initialize(nodes)
      @nodes = nodes.dup
    end

    def run_start_hooks
      nodes.each { |node| run_hook(node, 'start') }
    end

    def process
      nodes.each do |node|
        event_files(node).each { |f| process_event_file(f) }
      end
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
        process_event_file node.build_complete_path
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

    # The build complete event is special as it needs run at the end
    # This ensures that other events are read before the complete event is
    def event_files(node)
      Dir[File.join(node.event_dir, '**/*')].reject do |f|
        File.directory?(f) || (File.basename(f) == 'complete')
      end
    end

    def process_event_file(file)
      path_arr = file.split(File::SEPARATOR)
      event = path_arr[-1]
      node_str = path_arr[-2]
      puts "#{node_str}: #{event}"
      content = File.read(file).chomp
      puts content unless content.empty?
      puts
      FileUtils.rm file
    end
  end
end
