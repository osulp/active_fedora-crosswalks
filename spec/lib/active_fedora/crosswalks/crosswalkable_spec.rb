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
          expect(asset.datastreams["RELS-EXT"].to_rels_ext).to include "info:fedora/test:testing"
        end
      end
    end
    context "when a field is appended to" do
      context "on the source datastream" do
        before(:each) do
          asset.add_relationship(:is_member_of_collection, "info:fedora/test:testing")
          asset.add_relationship(:is_member_of_collection, "info:fedora/test:test2")
        end
        it "should set the crosswalked field" do
          expect(asset.xwalkMetadata.title).to eq ["info:fedora/test:testing", "info:fedora/test:test2"]
        end
      end
      context "on the crosswalked datastream" do
        before(:each) do
          asset.xwalkMetadata.title = "info:fedora/test:testing"
          asset.xwalkMetadata.title << "info:fedora/test:test2"
        end
        it "should set the source field" do
          expect(asset.relationships(:is_member_of_collection)).to eq ["info:fedora/test:testing", "info:fedora/test:test2"]
        end
      end
    end
  end
  context "crosswalking RDF to OM" do
    before(:each) do
      CrosswalkAsset.has_metadata :name => 'descMetadata', :type => DummyOmDatastream
      CrosswalkAsset.has_metadata :name => 'xwalkMetadata', :type => ExampleRdfDatastream do |ds|
        ds.crosswalk :field => :title, :to => [:name, :family_name], :in => :descMetadata
      end
    end
    context "when data is set" do
      context "on the source datastream" do
        before(:each) do
          asset.descMetadata.content = File.read(File.join(FIXTURE_PATH, 'fixture_xml.xml'))
          expect(asset.descMetadata.name(0).family_name).to eq ["Horn"]
        end
        it "should set the crosswalked field" do
          expect(asset.xwalkMetadata.title).to eq ["Horn", "Caesar"]
        end
        it "should serialize the crosswalk" do
          expect(asset.xwalkMetadata.content).to include("Horn")
          expect(asset.xwalkMetadata.content).to include("Caesar")
        end
      end
      context "on the crosswalked datastream" do
        before(:each) do
          asset.xwalkMetadata.title = "test"
        end
        it "should set the source field" do
          expect(asset.descMetadata.name.family_name).to eq ["test"]
        end
        it "should serialize the source" do
          expect(asset.descMetadata.content).to include("test")
        end
      end
    end
    context "when data is appended" do
      context "on the crosswalk datastream" do
        before(:each) do
          asset.descMetadata.content = File.read(File.join(FIXTURE_PATH, 'fixture_xml.xml'))
          asset.xwalkMetadata.title << "test"
        end
        it "should add the metadata to the source field" do
          expect(asset.descMetadata.name.family_name).to eq ["Horn", "test", "Caesar"]
        end
      end
    end
  end
  context "crosswalking OM to RDF" do
    before(:each) do
      CrosswalkAsset.has_metadata :name => 'descMetadata', :type => ExampleRdfDatastream
      CrosswalkAsset.has_metadata :name => 'xwalkMetadata', :type => DummyOmDatastream do |ds|
        ds.crosswalk :field => [:name, :family_name], :to => :title, :in => :descMetadata
      end
    end
    context "when data is set" do
      context "on the crosswalk datastream" do
        before(:each) do
          asset.xwalkMetadata.content = File.read(File.join(FIXTURE_PATH, 'fixture_xml.xml'))
          expect(asset.xwalkMetadata.name(0).family_name).to eq ["Horn"]
        end
        it "should set the crosswalked field" do
          expect(asset.descMetadata.title).to eq ["Horn", "Caesar"]
        end
      end
    end
  end
end
