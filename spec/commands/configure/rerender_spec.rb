
# frozen_string_literal: true

require 'commands/configure/rerender'
require 'shared_examples/render_domain_templates'

RSpec.describe Metalware::Commands::Configure::Rerender do
  include_examples :render_domain_templates, Metalware::Commands::Configure::Rerender
end
