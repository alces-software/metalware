# frozen_string_literal: true

require 'file_path'

module Metalware
  module RenderMethods
    class RenderMethod
      class << self
        def render_to_staging(namespace, templater)
          file = template(namespace)
          templater.render(namespace, file, sync_location, **staging_opts)
        end

        # validate methods may return a truthy or falsey results
        # They may also raise an error which will be interpreted as false
        def validate(_file_content)
          raise NotImplementedError
        end

        def managed?
          true
        end

        private

        def run_in_temp_file(content)
          file = Tempfile.open(self.class.to_s.gsub('::', '-'))
          file.write(content)
          file.rewind
          yield file
        ensure
          file.close!
        end

        def staging_opts
          {
            managed: managed?,
            validator: name,
          }
        end

        def sync_location
          raise NotImplementedError
        end

        def template(_namespace)
          raise NotImplementedError
        end
      end
    end
  end
end
