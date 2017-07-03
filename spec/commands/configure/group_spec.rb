
require 'spec_utils'


RSpec.describe Metalware::Commands::Configure::Group do
  def run_configure_group(group)
    SpecUtils.run_command(
      Metalware::Commands::Configure::Group, group
    )
  end

  # XXX extract this
  def create_directory_hierarchy
    FileUtils.mkdir_p Metalware::Constants::METALWARE_CONFIGS_PATH
    FileUtils.touch Metalware::Constants::DEFAULT_CONFIG_PATH

    FileUtils.mkdir_p Metalware::Constants::CACHE_PATH
    FileUtils.mkdir_p File.join(Metalware::Constants::ANSWERS_PATH, 'groups')

    FileUtils.mkdir_p config.repo_path
    File.write config.configure_file, YAML.dump({
      questions: {},
      domain: {},
      group: {},
      node: {},
    })
  end

  let :config { Metalware::Config.new }
  let :groups_file {
    File.join(Metalware::Constants::CACHE_PATH, 'groups.yaml' )
  }
  let :groups_yaml { YAML.load_file(groups_file) }
  let :primary_groups { groups_yaml[:primary_groups] }

  context 'when `cache/groups.yaml` does not exist' do
    it 'creates it and inserts new primary group' do
      FakeFSHelper.new(config).run do
        create_directory_hierarchy
        run_configure_group 'testnodes'

        expect(primary_groups).to eq [
          'testnodes'
        ]
      end
    end
  end


  context 'when `cache/groups.yaml` exists' do
    it 'inserts primary group if new' do
      FakeFSHelper.new(config).run do
        create_directory_hierarchy
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
      FakeFSHelper.new(config).run do
        create_directory_hierarchy
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
