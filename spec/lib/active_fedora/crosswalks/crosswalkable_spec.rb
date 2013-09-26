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
        it "should serialize the data" do
          expect(asset.xwalkMetadata.content).to include "Test"
        end
      end
      context "on the crosswalked datastream" do
        before(:each) do
          asset.xwalkMetadata.title = "Test"
        end
        it "should set the source field" do
          expect(asset.descMetadata.other_title).to eq ["Test"]
        end
        it "should serialize the data" do
          expect(asset.descMetadata.content).to include "Test"
        end
      end
    end
    context "when a field is appended to" do
      before(:each) do
        asset.descMetadata.other_title = "Testing"
        asset.xwalkMetadata.title = "Testing"
      end
      context "on the source datastream" do
        before(:each) do
          asset.descMetadata.other_title << "Test2"
        end
        it "should append to the crosswalked field" do
          expect(asset.xwalkMetadata.title).to eq ["Testing", "Test2"]
        end
        it "should serialize the data" do
          expect(asset.xwalkMetadata.content).to include "Testing"
          expect(asset.xwalkMetadata.content).to include "Test2"
        end
      end
      context "on the crosswalked datastream" do
        before(:each) do
          asset.xwalkMetadata.title << "Test2"
        end
        it "should append to the source field" do
          expect(asset.descMetadata.other_title).to eq ["Testing", "Test2"]
        end
        it "should serialize the data" do
          expect(asset.descMetadata.content).to include "Testing"
          expect(asset.descMetadata.content).to include "Test2"
        end
      end
    end
  end
  context "crosswalking RDF to RELS-EXT" do
    before(:each) do
      CrosswalkAsset.has_metadata :name => 'xwalkMetadata', :type => ExampleRdfDatastream do |ds|
        ds.crosswalk :field => :title, :to => :is_member_of_collection, :in => "RELS-EXT"
      end
    end
    context "when a field is set" do
      context "on the source datastream" do
        before(:each) do
          asset.add_relationship(:is_member_of_collection, "info:fedora/test:test")
        end
        it "should set the crosswalked field" do
          expect(asset.xwalkMetadata.title).to eq ["info:fedora/test:test"]
        end
        it "should serialize the data" do
          expect(asset.xwalkMetadata.content).to include "info:fedora/test:test"
        end
      end
      context "on the crosswalked datastream" do
        before(:each) do
          asset.xwalkMetadata.title = "info:fedora/test:testing"
        end
        it "should set the source field" do
          expect(asset.relationships(:is_member_of_collection)).to eq ["info:fedora/test:testing"]
        end
        it "should serialize the data" do
          expect(asset.datastreams["RELS-EXT"].content).to include "info:fedora/test:testing"
        end
      end
    end
  end
end
