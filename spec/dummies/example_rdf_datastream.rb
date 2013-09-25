class ExampleRdfDatastream < ActiveFedora::NtriplesRDFDatastream
  include ActiveFedora::Crosswalks::Crosswalkable
  map_predicates do |map|
    map.title(:in => RDF::DC)
  end
end