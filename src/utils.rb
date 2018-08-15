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

      def run_command(command_class, *args, stderr: $stderr, **options_hash)
        old_stderr = $stderr
        $stderr = stderr

        options = Commander::Command::Options.new
        options_hash.map do |option, value|
          option_setter = (option.to_s + '=').to_sym
          options.__send__(option_setter, value)
        end

        command_class.new(args, options)
      rescue StandardError => e
        warn e.message
        warn e.backtrace
        raise e
      ensure
        $stderr = old_stderr
      end

      def in_gui?
        defined? Rails
      end

      def copy_via_temp_file(source, destination)
        temp_name = File.basename(destination, '.*')
        content = File.read(source)
        create_temp_file(temp_name, content) do |path|
          yield path
          FileUtils.cp(path, destination)
        end
      end

      private

      # From
      # https://www.safaribooksonline.com/library/view/ruby-cookbook/0596523696/ch01s15.html.
      def wrap(string, width)
        string.gsub(/(.{1,#{width}})(\s+|\Z)/, "\\1\n")
      end

      def create_temp_file(name, content)
        file = Tempfile.new(name)
        file.write(content)
        file.flush
        yield file.path
      ensure
        file.close
        file.unlink
      end
    end
  end
end
