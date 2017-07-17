
# frozen_string_literal: true

RSpec.describe Metalware::Templating::MagicNamespace do
  # Note: many `MagicNamespace` features are tested at the `Templater` level
  # instead.

  describe '#groups' do
    subject do
      Metalware::Templating::MagicNamespace.new(
        config: Metalware::Config.new
      )
    end

    it 'calls the passed block with a group namespace for each primary group' do
      FileSystem.test do |fs|
        fs.with_groups_cache_fixture('cache/groups.yaml')

        group_names = []
        subject.groups do |group|
          expect(group).to be_a(Metalware::Templating::GroupNamespace)
          group_names << group.name
        end

        expect(group_names).to eq(['some_group', 'testnodes'])
      end
    end
  end
end
