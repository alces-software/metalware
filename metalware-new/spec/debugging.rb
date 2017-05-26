
module Debugging
  class << self
    # Print all paths present in the filesystem; useful when debugging
    # `FakeFS`.
    def print_fs
      Dir['**/*'].each do |f|
        puts "f: #{f}"
      end
    end
  end
end
