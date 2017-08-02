
# frozen_string_literal: true

require 'domain_templates_renderer'

module Metalware
  module Commands
    module Configure
      class Rerender < CommandHelpers::BaseCommand
        private

        def setup(_args, _options); end

        def run
          DomainTemplatesRenderer.new(config).render
        end
      end
    end
  end
end
