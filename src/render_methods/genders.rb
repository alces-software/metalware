# frozen_string_literal: true

module Metalware
  module RenderMethods
    class Genders < RenderMethod
      class << self
        def validate(content)
          run_in_temp_file(content) do |file|
            NodeattrInterface.validate_genders_file(file.path)
          end
        end

        private

        def sync_location
          FilePath.genders
        end

        def template
          FilePath.template_path('genders')
        end
      end
    end
  end
end
