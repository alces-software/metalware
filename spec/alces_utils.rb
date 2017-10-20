
# frozen_string_literal: true

require 'namespaces/alces'
require 'config'
require 'active_support/core_ext/module/delegation'
require 'recursive_open_struct'
require 'spec_utils'

module AlcesUtils
  # Causes the testing version of alces (/config) to be used by metalware
  class << self
    def start(example_group, config: nil)
      # The mocking of the namespace expects the local node to exist
      # However this means it needs to be in the genders file
      # By default the local_only gender file is used
      # However this does not prevent genders being mocked again
      example_group.before :each do
        SpecUtils.use_mock_genders(self, genders_file: 'genders/local_only')
      end

      example_group.instance_exec do
        let! :metal_config do
          test_config = Metalware::Config.new(config)
          allow(Metalware::Config).to receive(:new).and_return(test_config)
          test_config
        end

        let! :alces do
          test_alces = Metalware::Namespaces::Alces.new(metal_config)
          allow(Metalware::Namespaces::Alces).to \
            receive(:new).and_return(test_alces)
          # Allows the node method to be mocked
          test_alces.define_singleton_method(:node) { method_missing(:node) }
          test_alces
        end
      end
    end

    def included(base)
      start(base)
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
      new_config = Metalware::Constants::HASH_MERGER_DATA_STRUCTURE
                   .new(h) { |template_str| template_str }
      allow(namespace).to receive(:config).and_return(new_config)
    end

    def validation_off
      allow(metal_config).to receive(:validation).and_return(false)
    end

    def mock_strict(bool)
      metal_config.cli[:strict] = bool
    end

    def alces_default_to_domain_scope_off
      allow(metal_config).to \
        receive(:alces_default_to_domain_scope).and_return(false)
    end

    def with_blank_config_and_answer(namespace)
      allow(namespace).to receive(:config).and_return(OpenStruct.new)
      allow(namespace).to receive(:answer).and_return(OpenStruct.new)
    end

    def mock_node(name, *genders)
      genders = ['test-group'] if genders.empty?
      node = Metalware::Namespaces::Node.create(alces, name)
      with_blank_config_and_answer(node)
      allow(node).to receive(:genders).and_return(genders)
      nodes = alces.nodes
                   .reduce([]) { |memo, n| memo.push(n) }
                   .tap { |x| x.push(node) }
      metal_nodes = Metalware::Namespaces::MetalArray.new(nodes)
      allow(alces).to receive(:nodes).and_return(metal_nodes)
      allow(alces).to receive(:node).and_return(node)
    end

    private

    attr_reader :alces, :metal_config, :test

    # Is called on initialize
    def setup
    end

    # Allows the RSpec methods to be accessed
    def respond_to_missing?(s, *_a)
      test.respond_to?(s)
    end

    def method_missing(s, *a, &b)
      respond_to_missing?(s) ? test.send(s, *a, &b) : super
    end
  end
end
