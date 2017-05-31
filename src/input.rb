
require 'open-uri'


module Metalware
  module Input
    class << self
      def download(from_url, to_path)
        open(from_url) do |f|
          File.write(to_path, f.read)
        end
      end
    end
  end
end
