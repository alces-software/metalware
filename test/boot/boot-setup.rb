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
require "alces/stack/finder"

module BootTestSetup
  def setup
    set_up_templates
    set_finders
    set_inputs
    run_bash_cmd
  end

  def set_up_templates
    @default_template_location = "#{ENV['alces_REPO']}/templates/boot/"

    @template = "test.erb"
    @template_str = "Boot template, <%= nodename %>, " \
                    "<%= kernelappendoptions %>, <%= kickstart %>"
    File.write("#{@default_template_location}#{@template}", @template_str)

    @template_kickstart = "#{ENV['alces_REPO']}/templates/kickstart/test.erb"
    @template_str_kickstart =
      "Kickstart template, <%= nodename %>, <%= kernelappendoptions %>" \
      " <% if !permanent_boot %>false<% end %>"
    File.write(@template_kickstart, @template_kickstart)
    
    @template_pxe_firstboot = "firstboot.erb"
    @template_pxe_firstboot_str =
      'PXE template, <%= nodename %>, <%= permanent_boot ? "permanent" : "" %>' \
      " <%= kernelappendoptions %> <%= kickstart %>  <%= first_boot %>"
    File.write("#{@default_template_location}#{@template_pxe_firstboot}",
               @template_pxe_firstboot_str)
  end

  def set_finders
    @finder = Alces::Stack::Finder
                .new(@default_template_location, @template)
    @ks_finder = Alces::Stack::Finder
                .new(@default_template_location, @template_kickstart)
  end

  def set_inputs
    @input_base = {
      permanent_boot: false,
      template: @template,
      kernel_append: "KERNAL_APPEND",
      json: '{"json":"included","kernelappendoptions":"KERNAL_APPEND"}'
    }
    
    @input_nodename = {}.merge(@input_base).merge({ nodename: "slave04" })
    @input_group = {}.merge(@input_base).merge({
        nodename: "SHOULD_BE_OVERRIDDEN",
        group: "slave"
      })
    
    @input_nodename_kickstart = {}.merge(@input_nodename)
                                  .merge({ kickstart: @template_kickstart })
    @input_group_kickstart = {}.merge(@input_group)
                               .merge({ kickstart: @template_kickstart })
    
    @input_nodename_script = {}.merge(@input_nodename)
                               .merge({ scripts: "empty.erb" })
    @input_group_script = {}.merge(@input_group)
                            .merge({ scripts: "empty.erb ,empty2.sh,empty3.csh , empty4.sh" }) 
  end

  def run_bash_cmd
    `cp /etc/hosts /etc/hosts.copy`
    `metal hosts -a -g #{@input_group[:group]} -j '{"iptail":"<%= index + 100 %>"}'`
    `mkdir -p /var/lib/tftpboot/pxelinux.cfg/`
    `mkdir -p /var/www/html/ks`
    `echo "" > #{ENV['alces_REPO']}/templates/scripts/empty2.sh`
    `echo "" > #{ENV['alces_REPO']}/templates/scripts/empty3.csh`
    `echo "" > #{ENV['alces_REPO']}/templates/scripts/empty4.sh.erb`
    `rm -rf /var/lib/tftpboot/pxelinux.cfg/*`
    `rm -rf /var/lib/metalware/rendered/ks/*`
    `rm -rf /var/lib/metalware/cache/*`
    `rm -rf /var/www/html/scripts/*`
    `rm -rf /var/lib/metalware/rendered/scripts/*`
  end

  def teardown
    `rm -f #{ENV['alces_REPO']}/templates/scripts/empty2.sh`
    `rm -f #{ENV['alces_REPO']}/templates/scripts/empty3.csh`
    `rm -f #{ENV['alces_REPO']}/templates/scripts/empty4.sh.erb`
    `rm #{@default_template_location}#{@template}`
    `rm #{@default_template_location}#{@template_pxe_firstboot}`
    `rm -f #{@template_kickstart}`
    `mv /etc/hosts.copy /etc/hosts`
  end
end