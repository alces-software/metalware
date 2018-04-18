
# frozen_string_literal: true

module Metalware
  class ManagedFile
    MANAGED_START_MARKER = 'METALWARE_START'
    MANAGED_START = "########## #{MANAGED_START_MARKER} ##########"
    MANAGED_END_MARKER = 'METALWARE_END'
    MANAGED_END = "########## #{MANAGED_END_MARKER} ##########"
    MANAGED_COMMENT = Utils.commentify(
      <<-EOF.squish
      This section of this file is managed by Alces Metalware. Any changes made
      to this file between the #{MANAGED_START_MARKER} and
      #{MANAGED_END_MARKER} markers may be lost; you should make any changes
      you want to persist outside of this section or to the template directly.
    EOF
    )

    class << self
      def content(managed_file, rendered_content)
        pre, post = split_on_managed_section(
          current_file_contents(managed_file)
        )
        [pre, managed_section(rendered_content.strip), post].join
      end

      private

      def current_file_contents(file)
        File.exist?(file) ? File.read(file).strip : ''
      end

      def split_on_managed_section(file_contents)
        if file_contents.include? MANAGED_START
          pre, rest = file_contents.split(MANAGED_START)
          _, post = rest.split(MANAGED_END)
          [pre, post]
        else
          [file_contents + "\n\n", nil]
        end
      end

      def managed_section(rendered_template)
        [
          MANAGED_START,
          MANAGED_COMMENT,
          rendered_template,
          MANAGED_END,
        ].join("\n") + "\n"
      end
    end
  end
end
