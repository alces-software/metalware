
require 'spec_utils'
require 'filesystem'


RSpec.describe Metalware::Commands::Configure::Group do
  def run_configure_group(group)
    SpecUtils.run_command(
      Metalware::Commands::Configure::Group, group
    )
  end

  let :config { Metalware::Config.new }
  let :groups_file {
    File.join(Metalware::Constants::CACHE_PATH, 'groups.yaml' )
  }
  let :groups_yaml { YAML.load_file(groups_file) }
  let :primary_groups { groups_yaml[:primary_groups] }

  context 'when `cache/groups.yaml` does not exist' do
    it 'creates it and inserts new primary group' do
      FileSystem.test do |fs|
        fs.with_minimal_repo

        run_configure_group 'testnodes'

        expect(primary_groups).to eq [
          'testnodes'
        ]
      end
    end
  end


  context 'when `cache/groups.yaml` exists' do
    it 'inserts primary group if new' do
      FileSystem.test do |fs|
        fs.with_minimal_repo
        File.write groups_file, YAML.dump({
          primary_groups: [
            'first_group',
          ]
        })

        run_configure_group 'second_group'

        expect(primary_groups).to eq [
          'first_group',
          'second_group',
        ]
      end

    end

    it 'does nothing if primary group already presnt' do
      FileSystem.test do |fs|
        fs.with_minimal_repo
        File.write groups_file, YAML.dump({
          primary_groups: [
            'first_group',
            'second_group',
          ]
        })

        run_configure_group 'second_group'

        expect(primary_groups).to eq [
          'first_group',
          'second_group',
        ]
      end

    end
  end
end
