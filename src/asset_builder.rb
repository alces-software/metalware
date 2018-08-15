# frozen_string_literal: true

require 'records/layout'
require 'records/asset'

module Metalware
  class AssetBuilder
    attr_reader :stack

    def initialize
      @stack ||= []
    end

    def push_asset(name, layout_or_type)
      if (details = Records::Layout.type_or_layout(layout_or_type))
        stack.push(Asset.new(self, name, details.path, details.type))
      else
        MetalLog.warn <<-EOF.squish
          Failed to add asset: "#{name}". Could not find layout:
          "#{layout_or_type}"
        EOF
      end
    end

    def pop_asset
      asset = stack.pop
      if asset.nil?
        nil
      elsif Records::Asset.available?(asset.name)
        asset
      else
        pop_asset
      end
    end

    def edit_asset(name)
      path = Records::Asset.path(name, missing_error: true)
      type = Records::Asset.type_from_path(path)
      Asset.new(self, name, path, type).edit_and_save
    end

    Asset = Struct.new(:builder, :name, :source_path, :type) do
      def edit_and_save
        Utils::Editor.open_copy(source_path, asset_path) do |temp_path|
          validate_and_generate_sub_assets(temp_path)
        end
      end

      def save
        Utils.copy_via_temp_file(source_path, asset_path) do |path|
          raise_invalid_source unless validate_and_generate_sub_assets(path)
        end
      end

      def asset_path
        FilePath.asset(type.pluralize, name).tap do |path|
          FileUtils.mkdir_p(File.dirname(path))
        end
      end

      private

      def raise_invalid_source
        raise ValidationFailure, <<-EOF.squish
          Failed to add asset: "#{name}". Please check the layout is valid:
          "#{source_path}"
        EOF
      end

      def validate_and_generate_sub_assets(path)
        return false unless (data = Validation::Asset.valid_file?(path))
        new_data = convert_sub_assets(data)
        Metalware::Data.dump(path, new_data)
      end

      def convert_sub_assets(value)
        case value
        when String
          convert_sub_asset_string(value)
        when Array
          value.map { |v| convert_sub_assets(v) }
        when Hash
          value.deep_merge(value) { |_, _, v| convert_sub_assets(v) }
        else
          value
        end
      end

      def convert_sub_asset_string(str)
        return str unless str.match?(/\A[^\^]+\^[^\^]+\Z/)
        sub_type_layout = str.match(/\A.+(?=\^)/).to_s
        append_name = str.match(/(?<=\^).+\Z/).to_s
        sub_asset_name = "#{name}-#{append_name}"
        builder.push_asset(sub_asset_name, sub_type_layout)
        '^' + sub_asset_name
      end
    end
  end
end
