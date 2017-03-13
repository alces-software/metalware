#==============================================================================
# Copyright (C) 2017 Stephen F. Norledge and Alces Software Ltd.
#
# This file/package is part of Alces Metalware.
#
# Alces Metalware is free software: you can redistribute it and/or
# modify it under the terms of the GNU Affero General Public License
# as published by the Free Software Foundation, either version 3 of
# the License, or (at your option) any later version.
#
# Alces Metalware is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
# Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with this package.  If not, see <http://www.gnu.org/licenses/>.
#
# For more information on the Alces Metalware, please visit:
# https://github.com/alces-software/metalware
#==============================================================================
module BootTestSetup
  def setup
    @default_template_location = "#{ENV['alces_BASE']}/etc/templates/boot/"
    @template = "test.erb"
    @template_str = "Boot template, <%= nodename %>, <%= kernelappendoptions %>"
    @template_str_kickstart =
      "Kickstart template, <%= nodename %>, <%= kernelappendoptions %>" \
      " <%= kickstart %> <% if !permanentboot %>false<% end %>"
    @template_kickstart = "#{ENV['alces_BASE']}/etc/templates/kickstart/test.erb"
    @template_pxe_firstboot_str =
      "PXE template, <%= nodename %>, <%= kernelappendoptions %> " \
      "<%= kickstart %> <% if !permanentboot %>false<% end %> <%= firstboot %>"
    @template_pxe_firstboot = "firstboot.erb"
    File.write("#{@default_template_location}#{@template_pxe_firstboot}",
               @template_pxe_firstboot_str)
    File.write(@template_kickstart, @template_str_kickstart)
    File.write("#{@default_template_location}#{@template}", @template_str)
    File.write("#{ENV['alces_BASE']}/etc/templates/kickstart/#{@template}",
               @template_str)
    @finder = Alces::Stack::Templater::Finder
                .new(@default_template_location, @template)
    @ks_finder = Alces::Stack::Templater::Finder
                .new(@default_template_location, @template_kickstart)
    @input_base = {
      permanentboot: false,
      template: @template,
      kernel_append: "KERNAL_APPEND",
      json: '{"json":"included","kernelappendoptions":"KERNAL_APPEND"}'
    }
    @input_nodename = {}.merge(@input_base)
    @input_nodename[:nodename] = "slave04"
    @input_group = {
      nodename: "SHOULD_BE_OVERRIDDEN",
      group: "slave",
      permanent_boot_flag: false
    }
    @input_group.merge!(@input_base)
    @input_group_kickstart = {}.merge(@input_group)
                               .merge({ kickstart: @template_kickstart })
    @input_group_kickstart[:template] = @template_kickstart
    @input_nodename_kickstart = {}.merge(@input_nodename)
                                  .merge({ kickstart: @template_kickstart })
    @input_nodename_kickstart[:template] = @template_kickstart
    @input_nodename_script = {}.merge(@input_nodename).merge({ script: "empty" })
    @input_group_script = {}.merge(@input_group).merge({ script: "empty" })
    `cp /etc/hosts /etc/hosts.copy`
    `metal hosts -a -g #{@input_group[:group]} -j '{"iptail":"<%= index + 100 %>"}'`
    `mkdir -p /var/lib/tftpboot/pxelinux.cfg/`
    `mkdir -p /var/www/html/ks`
    `echo "" > #{ENV['alces_BASE']}/etc/templates/scripts/`
    `rm -rf /var/lib/tftpboot/pxelinux.cfg/*`
    `rm -rf /var/lib/metalware/rendered/ks/*`
    `rm -rf /var/lib/metalware/cache/*`
  end

  def teardown
    `rm #{@default_template_location}#{@template}`
    `rm #{@default_template_location}#{@template_pxe_firstboot}`
    `rm #{ENV['alces_BASE']}/etc/templates/kickstart/#{@template}`
    `rm -f #{@template_kickstart}`
    `mv /etc/hosts.copy /etc/hosts`
  end
end