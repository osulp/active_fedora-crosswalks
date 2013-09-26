# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'active_fedora/crosswalks/version'

Gem::Specification.new do |spec|
  spec.name          = "active_fedora-crosswalks"
  spec.version       = ActiveFedora::Crosswalks::VERSION
  spec.authors       = ["Trey Terrell"]
  spec.email         = ["trey.terrell@oregonstate.edu"]
  spec.description   = %q{Enables metadata crosswalking between ActiveFedora datastreams.}
  spec.summary       = %q{Enables metadata crosswalking between ActiveFedora datastreams.}
  spec.homepage      = "https://github.com/osulp/active_fedora-crosswalks"
  spec.license       = "Apache v2"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "guard"
  spec.add_development_dependency "guard-rspec"
  spec.add_development_dependency 'jettywrapper'
  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'shoulda-matchers'

  spec.add_dependency 'active-fedora'
  spec.add_dependency 'activesupport', '>= 3.2.0', '< 5.0'
  spec.add_dependency 'bagit'
  spec.add_dependency 'mime-types'
end
