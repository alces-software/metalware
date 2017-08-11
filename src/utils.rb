
# frozen_string_literal: true

module Metalware
  module Utils
    class << self
      def commentify(string, comment_char: '#', line_length: 80)
        comment_string = "#{comment_char} "
        max_commented_line_length = line_length - comment_string.length

        wrap(string, max_commented_line_length)
          .split("\n")
          .map { |line| line.prepend(comment_string) }
          .join("\n")
      end

      private

      # From
      # https://www.safaribooksonline.com/library/view/ruby-cookbook/0596523696/ch01s15.html.
      def wrap(string, width)
        string.gsub(/(.{1,#{width}})(\s+|\Z)/, "\\1\n")
      end
    end
  end
end
