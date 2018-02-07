
# frozen_string_literal: true

require 'namespaces/alces'
require 'config'
require 'active_support/core_ext/module/delegation'
require 'recursive_open_struct'
require 'spec_utils'
require 'filesystem'

module AlcesUtils
  GENDERS_FILE_REGEX = /-f [[:graph:]]+/
  # Causes the testing version of alces (/config) to be used by metalware
  class << self
    def start(example_group, config: nil)
      example_group.instance_exec do
        let! :metal_config do
          AlcesUtils.check_and_raise_fakefs_error
          test_config = Metalware::Config.new(config)
          allow(Metalware::Config).to receive(:new).and_return(test_config)
          test_config
        end

        let! :alces do
          test_alces = Metalware::Namespaces::Alces.new
          allow(Metalware::Namespaces::Alces).to \
            receive(:new).and_return(test_alces)
          test_alces
        end

        #
        # Mocks nodeattr to use faked genders file
        #
        before :each do
          File.open(Metalware::FilePath.genders, 'a') { |f| f.puts('local local') } unless File.exist?(Metalware::FilePath.genders)

          allow(Metalware::NodeattrInterface)
            .to receive(:nodeattr).and_wrap_original do |method, *args|
            AlcesUtils.check_and_raise_fakefs_error
            path = AlcesUtils.nodeattr_genders_file_path(args[0])
            cmd = AlcesUtils.nodeattr_cmd_trim_f(args[0])
            genders_data = File.read(path)
            tempfile = nil
            begin
              FakeFS.without do
                tempfile = Tempfile.open('mock-genders')
                tempfile.write(genders_data)
                tempfile.close
              end
              mock_cmd = "nodeattr -f #{tempfile.path}"
              method.call(cmd, mock_nodeattr: mock_cmd)
            ensure
              FakeFS.without { tempfile&.unlink }
            end
          end
        end
      end
    end

    def included(base)
      start(base)
    end

    def nodeattr_genders_file_path(command)
      return Metalware::FilePath.genders unless command.include?('-f')
      command.match(AlcesUtils::GENDERS_FILE_REGEX)[0].sub('-f ', '')
    end

    def nodeattr_cmd_trim_f(command)
      command.sub(AlcesUtils::GENDERS_FILE_REGEX, '')
    end

    def redirect_std(*input, &_b)
      old = {
        stdout: $stdout,
        stderr: $stderr,
      }
      buffers = input.map { |k| [k, StringIO.new] }.to_h
      update_std_files buffers
      yield
      buffers.each { |_k, v| v.rewind }
      buffers
    ensure
      update_std_files old
    end

    def update_std_files(**hash)
      $stdout = hash[:stdout] if hash[:stdout]
      $stderr = hash[:stderr] if hash[:stderr]
    end

    def kill_other_threads
      Thread.list
            .reject { |t| t == Thread.current }
            .tap { |t| t.each(&:kill) }
            .tap { |t| t.each(&:join) }
    end

    def mock(test, *a, &b)
      mock_block = lambda do |*_inputs|
        mock_alces = AlcesUtils::Mock.new(self)
        mock_alces.instance_exec(&b)
      end

      if a.empty?
        test.instance_exec(&mock_block)
      else
        test.before(*a, &mock_block)
      end
    end

    def check_and_raise_fakefs_error
      msg = 'Can not use AlcesUtils without FakeFS'
      raise msg unless FakeFS.activated?
    end

    def default_group
      'default-test-group'
    end
  end

  # The following method(s) will be included with AlcesUtils
  # Use AlcesUtils.start to skip the include but still setup mocking
  def render_template(template)
    alces.render_erb_template(template)
  end

  # The following methods have to be initialized with a individual test
  # Example, when using: 'before :each { AlcesUtils::Mock.new(self) }'
  class Mock
    def initialize(individual_spec_test)
      @test = individual_spec_test
      @alces = test.instance_exec { alces }
      @metal_config = test.instance_exec { metal_config }
    end

    # Used to test basic templating features, avoid use if possible
    def define_method_testing(&block)
      alces.send(:define_singleton_method, :testing, &block)
    end

    def config(namespace, h = {})
      allow(namespace).to receive(:config).and_return(hash_object(h))
    end

    def answer(namespace, h = {})
      allow(namespace).to receive(:answer).and_return(hash_object(h))
    end

    def validation_off
      stub_const('Metalware::Constants::SKIP_VALIDATION', true)
    end

    def build_poll_sleep(time)
      stub_const('Metalware::Constants::BUILD_POLL_SLEEP', time)
    end

    def with_blank_config_and_answer(namespace)
      allow(namespace).to receive(:config).and_return(OpenStruct.new)
      allow(namespace).to receive(:answer).and_return(OpenStruct.new)
    end

    def hexadecimal_ip(node)
      hex = "#{node.name}_HEX_IP"
      allow(node).to receive(:hexadecimal_ip).and_return(hex)
    end

    def mock_node(name, *genders)
      AlcesUtils.check_and_raise_fakefs_error
      raise_if_node_exists(name)
      add_node_to_genders_file(name, *genders)
      Metalware::Namespaces::Node.create(alces, name).tap do |node|
        with_blank_config_and_answer(node)
        hexadecimal_ip(node)
        new_nodes = alces.nodes.reduce([node], &:push)
        metal_nodes = Metalware::Namespaces::MetalArray.new(new_nodes)
        allow(alces).to receive(:nodes).and_return(metal_nodes)
        allow(alces).to receive(:node).and_return(node)
      end
    end

    def mock_group(name)
      AlcesUtils.check_and_raise_fakefs_error
      group_cache.add(name)
      alces.instance_variable_set(:@groups, nil)
      alces.instance_variable_set(:@group_cache, nil)
      group = alces.groups.find_by_name(name)
      with_blank_config_and_answer(group)
      allow(alces).to receive(:group).and_return(group)
    end

    private

    attr_reader :alces, :metal_config, :test

    def raise_if_node_exists(name)
      return unless File.exist? Metalware::FilePath.genders
      msg = "Node '#{name}' already exists"
      raise Metalware::InternalError, msg if alces.nodes.find_by_name(name)
    end

    def add_node_to_genders_file(name, *genders)
      genders = [AlcesUtils.default_group] if genders.empty?
      genders_entry = "#{name} #{genders.join(',')}\n"
      File.write(Metalware::FilePath.genders, genders_entry, mode: 'a')
    end

    # Allows the RSpec methods to be accessed
    def respond_to_missing?(s, *_a)
      test.respond_to?(s)
    end

    def method_missing(s, *a, &b)
      respond_to_missing?(s) ? test.send(s, *a, &b) : super
    end

    def group_cache
      @group_cache ||= Metalware::GroupCache.new
    end

    def hash_object(h = {})
      Metalware::Constants::HASH_MERGER_DATA_STRUCTURE.new(h) do |str|
        str
      end
    end
  end
end
