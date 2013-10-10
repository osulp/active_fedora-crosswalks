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
  describe "crosswalking RDF to RDF" do
    before(:each) do
      CrosswalkAsset.has_metadata :name => 'descMetadata', :type => ExampleRdfDatastream
      CrosswalkAsset.has_metadata :name => 'xwalkMetadata', :type => ExampleRdfDatastream do |ds|
        ds.crosswalk :field => :title, :to => :other_title, :in => :descMetadata
      end
    end
    it "should be able to reload" do
      expect {asset.load_datastreams}.not_to raise_error
    end
    context "when content is set directly" do
      context "on the crosswalk datastream" do
        before(:each) do
          asset.xwalkMetadata.title = "Test"
          old_content = asset.xwalkMetadata.content
          asset.xwalkMetadata.title = "Testing"
          asset.xwalkMetadata.content = old_content
        end
        it "should set the source datastream" do
          expect(asset.descMetadata.other_title).to eq ["Test"]
        end
      end
      context "on the source datastream" do
        before(:each) do
          asset.descMetadata.other_title = "Test"
          old_content = asset.descMetadata.content
          asset.descMetadata.other_title = "Testing"
          asset.descMetadata.content = old_content
        end
        it "should set the crosswalked datastream" do
          expect(asset.xwalkMetadata.title).to eq ["Test"]
        end
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
  describe "transforms" do
    context "when you pass a transform" do
      context "but you don't pass a reverse transform" do
        before(:each) do
          CrosswalkAsset.has_metadata :name => 'descMetadata', :type => ExampleRdfDatastream
          CrosswalkAsset.has_metadata :name => 'xwalkMetadata', :type => ExampleRdfDatastream do |ds|
            ds.crosswalk :field => :title, :to => :other_title, :in => :descMetadata, :transform => Proc.new{|x| "bla_#{x}"}
          end
        end
        it "should raise an error when you try to initialize the object" do
          expect{asset}.to raise_error
        end
      end
      context "as well as a reverse transform (for RDF)" do
        before(:each) do
          CrosswalkAsset.has_metadata :name => 'descMetadata', :type => ExampleRdfDatastream
          CrosswalkAsset.has_metadata :name => 'xwalkMetadata', :type => ExampleRdfDatastream do |ds|
            ds.crosswalk :field => :title, :to => :other_title, :in => :descMetadata, :transform => Proc.new{|x| "bla_#{x}"},
                         :reverse_transform => Proc.new{|x| x.split("bla_").last}
          end
        end
        context "when a field is set" do
          context "on the source datastream" do
            before(:each) do
              asset.descMetadata.other_title = "bla"
            end
            it "should transform the value" do
              expect(asset.xwalkMetadata.title).to eq ["bla_bla"]
            end
            it "should leave the source datastream correct" do
              expect(asset.descMetadata.other_title).to eq ["bla"]
            end
          end
          context "on the crosswalked datastream" do
            before(:each) do
              asset.xwalkMetadata.title = "bla_bla"
            end
            it "should reverse transform the value for the source datastream" do
              expect(asset.descMetadata.other_title).to eq ["bla"]
            end
            it "should leave the crosswalk datastream correct" do
              expect(asset.xwalkMetadata.title).to eq ["bla_bla"]
            end
          end
        end
      end
      context "as well as a reverse transform (for Rels)" do
        before(:each) do
          CrosswalkAsset.has_metadata :name => 'xwalkMetadata', :type => ExampleRdfDatastream do |ds|
            ds.crosswalk :field => :title, :to => :is_member_of_collection, :in => "RELS-EXT", :transform => Proc.new{|x| x.split("info:fedora/").last},
                         :reverse_transform => Proc.new{|x| "info:fedora/#{x}" }
          end
        end
        context "when a field exists prior to crosswalking (previous data in graph)" do
          before(:each) do
            asset.xwalkMetadata.set_value(asset.xwalkMetadata.rdf_subject, :title, "test:testing")
          end
          it "should maintain that value" do
            expect(asset.xwalkMetadata.title).to eq ["test:testing"]
          end
          it "should perform the transform to rels" do
            asset.xwalkMetadata.title # Have to call this to perform the crosswalk right now. Calls sync_values.
            expect(asset.relationships(:is_member_of_collection)).to eq ["info:fedora/test:testing"]
          end
        end
        context "when a field is set" do
          context "on the source datastream" do
            before(:each) do
              asset.add_relationship(:is_member_of_collection, "info:fedora/test:test")
            end
            it "should transform the value" do
              expect(asset.xwalkMetadata.title).to eq ["test:test"]
            end
            it "should leave the source datastream correct" do
              expect(asset.relationships(:is_member_of_collection)).to eq ["info:fedora/test:test"]
            end
          end
          context "on the crosswalked datastream" do
            before(:each) do
              asset.xwalkMetadata.title = "test:test"
            end
            it "should reverse transform the value for the source datastream" do
              expect(asset.relationships(:is_member_of_collection)).to eq ["info:fedora/test:test"]
            end
            it "should leave the crosswalk datastream correct" do
              expect(asset.xwalkMetadata.title).to eq ["test:test"]
            end
          end
        end
      end
    end
  end
  describe "crosswalking RDF to RELS-EXT" do
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
  describe "crosswalking RDF to OM" do
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
          expect(asset.descMetadata.name.family_name).to eq ["Horn", "Caesar", "test"]
        end
      end
    end
  end
  describe "crosswalking OM to RDF" do
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
        xit "should set the crosswalked field" do
          expect(asset.descMetadata.title).to eq ["Horn", "Caesar"]
        end
      end
    end
  end
end
