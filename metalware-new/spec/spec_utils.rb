
module SpecUtils
  GENDERS_FILE = File.join(FIXTURES_PATH, 'genders')

  class << self
    def use_mock_genders(example_group)
      # Use `instance_exec` to stub constant in the context of the passed RSpec
      # example group.
      example_group.instance_exec do
        stub_const("Metalware::Constants::NODEATTR_COMMAND", "nodeattr -f #{GENDERS_FILE}")
      end
    end
  end
end
