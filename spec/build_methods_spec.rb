
require 'alces_utils'

RSpec.describe Metalware::BuildMethods do
  describe '.build_method_for' do
    let :alces { Metalware::Namespaces::Alces.new }

    def build_method_for(node)
      described_class.build_method_for(node)
    end

    context 'when passed Local node namespace' do
      it 'gives `Local` build method for node' do
        local = Metalware::Namespaces::Node.create(alces, 'local')

        build_method = build_method_for(local)

        expect(build_method).to be_a(Metalware::BuildMethods::Local)
        expect(build_method.send(:node)).to be local
      end
    end

    context 'when passed non-Local node namespace' do
      let :node { Metalware::Namespaces::Node.create(alces, 'somenode') }
      let :build_method { build_method_for(node) }

      def mock_node_config(mock_config)
        allow(node).to receive(:config).and_return(
          OpenStruct.new(mock_config)
        )
      end

      it "errors when node's build_method is `local`" do
        mock_node_config(build_method: :local)

        expect do
          build_method
        end.to raise_error(Metalware::InvalidLocalBuild)
      end

      it "gives UEFI build method for node when node's build_method is `uefi-kickstart`" do
        mock_node_config(build_method: :'uefi-kickstart')

        expect(build_method).to be_a(Metalware::BuildMethods::Kickstarts::UEFI)
        expect(build_method.send(:node)).to be node
      end

      it "gives Basic build method for node when node's build_method is `basic`" do
        mock_node_config(build_method: :basic)

        expect(build_method).to be_a(Metalware::BuildMethods::Basic)
        expect(build_method.send(:node)).to be node
      end

      it "gives Pxelinux build method for node when node's build_method is anything else" do
        mock_node_config(build_method: :anything)

        expect(build_method).to be_a(Metalware::BuildMethods::Kickstarts::Pxelinux)
        expect(build_method.send(:node)).to be node
      end

      it "gives Pxelinux build method for node when node's build_method is unset" do
        mock_node_config({})

        expect(build_method).to be_a(Metalware::BuildMethods::Kickstarts::Pxelinux)
      end

      it "gives correct build method when node's build_method is a string" do
        mock_node_config(build_method: 'basic')

        expect(build_method).to be_a(Metalware::BuildMethods::Basic)
      end
    end
  end
end
