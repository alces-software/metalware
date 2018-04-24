# frozen_string_literal: true

require 'file_path'

module Metalware
  module Records
    class Path
      class << self
        # NOTE: Currently this method wraps the FilePath method
        # Eventually FilePath.asset will take a type input however
        # Records::Path will contain all the file globing and thus
        # will only require the name
        def asset(name)
          FilePath.asset(name)
        end
      end
    end
  end
end
