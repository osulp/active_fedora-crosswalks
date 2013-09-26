require 'spec_helper'

describe ActiveFedora::Crosswalks::Crosswalkable do
  let(:asset) {CrosswalkAsset.new}
  before(:each) do
    Object.send(:remove_const, :CrosswalkAsset) if Object.const_defined?(:CrosswalkAsset)
    class CrosswalkAsset < ActiveFedora::Base; end
  end
  after(:each) do
    Object.send(:remove_const, :CrosswalkAsset)
  end
  context "crosswalking RDF to RDF" do
    before(:each) do
      CrosswalkAsset.has_metadata :name => 'descMetadata', :type => ExampleRdfDatastream
      CrosswalkAsset.has_metadata :name => 'xwalkMetadata', :type => ExampleRdfDatastream do |ds|
        ds.crosswalk :field => :title, :to => :other_title, :in => :descMetadata
      end
    end
    context "when a field is set" do
      context "on the source datastream" do
        before(:each) do
          asset.descMetadata.other_title = "Test"
        end
        it "should set the crosswalked field" do
          expect(asset.xwalkMetadata.title).to eq ["Test"]
        end
      end
      context "on the crosswalked datastream" do
        before(:each) do
          asset.xwalkMetadata.title = "Test"
        end
        it "should set the source field" do
          expect(asset.descMetadata.other_title).to eq ["Test"]
        end
      end
    end
  end
end
