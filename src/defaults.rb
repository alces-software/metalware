
require 'constants'
require 'recursive-open-struct'


module Metalware
  module Defaults
    # When new defaults are added here you may also want to add these to the
    # option's help to be displayed.
    # TODO: Could have these displayed in help automatically by overriding
    # `Commander` method - not doing for now for simplicity of both writing the
    # code and as this may be too much magic.
    DEFAULTS = RecursiveOpenStruct.new({
      build: {
        kickstart: 'default',
        pxelinux: 'default',
      },
      dhcp: {
        template: 'default',
      },
      hosts: {
        template: 'default',
      },
      hunter: {
        # XXX Always default interface to Metalware build interface (where
        # possible)?
        interface: 'eth0',
        prefix: 'node',
        length: 2,
        start: 1,
      }
    })

    class << self
      def method_missing(name, *args, &block)
        DEFAULTS.send(name) || {}
      end
    end
  end
end
