
# frozen_string_literal: true

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

require 'dns/named'
require 'config'
require 'filesystem'
require 'exceptions'
require 'file_path'

RSpec.describe Metalware::DNS::Named do
  let :config { Metalware::Config.new }
  let :named { Metalware::DNS::Named.new(config) }
  let :file_path { Metalware::FilePath.new(config) }
  let :filesystem do
    FileSystem.setup do |fs|
      fs.with_minimal_repo
      named = 'named.conf.erb'
      fs.with_scripts_templates_fixtures("templates/#{named}", named)
      fs.with_config_fixture('configs/unit-test.yaml', 'domain.yaml')
    end
  end

  let :correct_base_named_conf do
    externaldns = named.send(:repo_config)[:externaldns]
    "DNS: #{externaldns}"
  end

  context 'without a setup named server' do
    before :each do
      allow(named).to receive(:setup?).and_return(false)
      # Prevents restart_named from running, DANGEROUS
      allow(named).to receive(:restart_named)
    end

    it "errors if external dns isn't set" do
      expect do
        named.update
      end.to raise_error(Metalware::MissingExternalDNS)
    end

    it 'sets up the named server' do
      filesystem.test do
        expect(named).to receive(:restart_named)
        named.update
        rendered_named_conf = File.read(file_path.base_named).chomp
        expect(rendered_named_conf).to eq(correct_base_named_conf)
      end
    end
  end

  context 'with a setup named server' do
    before :each do
      allow(named).to receive(:setup?).and_return(true)
      # Prevents restart_named from accidentally running, DANGEROUS
      expect(named).not_to receive(:restart_named)
    end

    it 'skips setup but updates named server' do
      filesystem.test do
        template_path = File.join(file_path.repo, "named/forward/default")
        File.write(template_path, "<%= alces_named.zone %>")

        expect(named).not_to receive(:setup)
        named.update

        expect(File.file?(file_path.metalware_named)).to eq(true)
        expect(File.file?(file_path.named_zone("fwd_named_zone"))).to eq(true)
        expect(File.file?(file_path.named_zone("rev_named_zone"))).to eq(true)
        expect(File.read(file_path.named_zone("fwd_named_zone"))).to eq("pri\n")
      end
    end
  end
end
