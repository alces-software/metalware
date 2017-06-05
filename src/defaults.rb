
require 'constants'
require 'recursive-open-struct'


module Metalware
  Defaults = RecursiveOpenStruct.new({
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
end
