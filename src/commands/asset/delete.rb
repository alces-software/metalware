# frozen_string_literal: true

require 'cache/asset'
require 'fileutils'

module Metalware
  module Commands
    module Asset
      class Delete < Metalware::CommandHelpers::BaseCommand
        private
      
        attr_reader :asset_name, :asset_path

        def setup
          @asset_name = args[0]
          @asset_path = FilePath.asset(asset_name)
        end

        def run
          error_if_asset_doesnt_exist
          unassign_asset(asset_name)
          delete_asset
        end

        def error_if_asset_doesnt_exist
          return if File.exist?(asset_path)
          raise InvalidInput, <<-EOF.squish
            The "#{asset_name}" asset does not yet exist to delete.
          EOF
        end
        
        def delete_asset
          FileUtils.rm asset_path
        end
      end
    end
  end
end
