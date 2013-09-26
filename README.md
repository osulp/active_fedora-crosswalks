# ActiveFedora::Crosswalks

Enables metadata crosswalking between ActiveFedora datastreams.

## Installation

Add this line to your application's Gemfile:

    gem 'active_fedora-crosswalks'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install active_fedora-crosswalks

## Usage

In the datastreams you'd like to enable for crosswalking include ActiveFedora::Crosswalks::Crosswalkable
Example:
```ruby
class ExampleRdfDatastream < ActiveFedora::NtriplesRDFDatastream
  include ActiveFedora::Crosswalks::Crosswalkable
end
```

### Example - Crosswalking between RDF Datastreams
```ruby
class Asset < ActiveFedora::Base
  has_metadata :name => 'descMetadata', :type => ExampleRdfDatastream
  has_metadata :name => 'xwalkMetadata', :type => ExampleRdfDatastream do |ds|
    ds.crosswalk :field => :title, :to => :other_title, :in => :descMetadata
  end
end
```

### Example - Crosswalking from Rels-EXT to RDF Datastreams
```ruby
class Asset < ActiveFedora::Base
  has_metadata :name => 'xwalkMetadata', :type => ExampleRdfDatastream do |ds|
    ds.crosswalk :field => :set, :to => :is_member_of_collection, :in => "RELS-EXT"
  end
end
```

### Example - Deep crosswalking from OM Datastreams to RDF
```ruby
class Asset < ActiveFedora::Base
  has_metadata :name => 'descMetadata', :type => DummyOmDatastream
  has_metadata :name => 'xwalkMetadata', :type => ExampleRdfDatastream do |ds|
    ds.crosswalk :field => :name, :to => [:name, :family_name], :in => :descMetadata
  end
end
```

**NOTE**: Currently there is no support for defining datastreams other than RDF datastreams as crosswalk destinations.
          Pull Requests Accepted.

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
