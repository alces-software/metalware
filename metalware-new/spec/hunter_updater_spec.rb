
require 'tempfile'

require 'hunter_updater'
require 'output'


describe Metalware::HunterUpdater do
  let :hunter_file { Tempfile.new.path }
  let :updater { Metalware::HunterUpdater.new(hunter_file) }

  def hunter_yaml
    YAML.load_file(hunter_file)
  end

  describe '#add' do
    it 'adds given node name and MAC address pairs to hunter file' do
      updater.add('somenode01', 'some_mac_address')
      expect(hunter_yaml).to eq({
        somenode01: 'some_mac_address',
      })

      updater.add('somenode02', 'another_mac_address')
      expect(hunter_yaml).to eq({
        somenode01: 'some_mac_address',
        somenode02: 'another_mac_address',
      })
    end

    context 'with existing hunter content' do
      before :each do
        File.write(hunter_file, YAML.dump({somenode01: 'some_mac_address'}))
      end

      it 'outputs info if replacing node name' do
        # Replaces existing entry with node name.
        expect(Metalware::Output).to receive(:stderr).with(
          /Replacing.*somenode01.*some_mac_address/
        )
        updater.add('somenode01', 'another_mac_address')
        expect(hunter_yaml).to eq({
          somenode01: 'another_mac_address',
        })

        # Does not replace when new node name.
        expect(Metalware::Output).not_to receive(:stderr)
        updater.add('somenode02', 'some_mac_address')
      end

      it 'outputs info if replacing MAC address' do
        # Replaces existing entry with MAC address.
        expect(Metalware::Output).to receive(:stderr).with(
          /Replacing.*some_mac_address.*somenode01/
        )
        updater.add('somenode02', 'some_mac_address')
        expect(hunter_yaml).to eq({
          somenode02: 'some_mac_address',
        })

        # Does not replace when new MAC address.
        expect(Metalware::Output).not_to receive(:stderr)
        updater.add('somenode01', 'another_mac_address')
      end
    end

    context 'when hunter file does not exist yet' do
      before :each do
        File.delete(hunter_file)
      end

      it 'creates it first' do
        updater.add('somenode01', 'some_mac_address')
        expect(hunter_yaml).to eq({
          somenode01: 'some_mac_address',
        })
      end
    end

  end
end
