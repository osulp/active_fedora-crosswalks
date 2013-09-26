require 'spec_helper'



describe ActiveFedora::Crosswalks::Crosswalker do
  let(:proper_arguments) {{:datastream => asset.xwalkMetadata, :field => :title, :to => :other_title, :in => :descMetadata}}
  let(:arguments) {proper_arguments}
  let(:asset) {CrosswalkAsset.new}
  subject (:crosswalker) {ActiveFedora::Crosswalks::Crosswalker.new(arguments)}
  before(:each) do
    class CrosswalkAsset < ActiveFedora::Base
      has_metadata :name => 'descMetadata', :type => ExampleRdfDatastream
      has_metadata :name => 'xwalkMetadata', :type => ExampleRdfDatastream
    end
    class CrosswalkAssetNoDatastream < ActiveFedora::Base
      has_metadata :name => 'xwalkMetadata', :type => ExampleRdfDatastream
    end
  end
  after(:each) do
    Object.send(:remove_const, :CrosswalkAsset)
  end
  describe ".validate!" do
    context "when the asset has valid datastreams" do
      it "should be valid by default" do
        expect{subject.validate!}.not_to raise_error
      end
      %w{field to in datastream}.each do |value|
        context "when #{value} isn't given" do
          let(:arguments) {proper_arguments.except(value.to_sym)}
          it "should be invalid" do
            expect {subject.validate!}.to raise_error
          end
        end
      end
    end
    context "when the asset doesn't have a datastream by the given name" do
      let(:asset) {CrosswalkAssetNoDatastream}
      it "should be invalid" do
        expect {subject.validate!}.to raise_error
      end
    end
  end
  describe ".perform_crosswalk!" do
    before(:each) do
      asset.descMetadata.other_title = "bla"
      subject.perform_crosswalk!
    end
    it "should populate the datastream's crosswalk_fields" do
      expect(asset.xwalkMetadata.crosswalk_fields).to eq [:title]
    end
    it "should build the crosswalk" do
      expect(asset.xwalkMetadata.title).to eq ["bla"]
    end
    it "should build the crosswalk writer" do
      asset.xwalkMetadata.title = "bla2"
      expect(asset.descMetadata.other_title).to eq ["bla2"]
    end
  end
end
