# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'dynosaur/version'

Gem::Specification.new do |spec|
  spec.name          = "dynosaur"
  spec.version       = Dynosaur::VERSION
  spec.authors       = ["Andy O'Neill", "Daniel Schwartz"]
  spec.email         = ["aoneill@harrys.com",  'daniel@harrys.com']
  spec.description   = %q{Heroku autoscaler based on plugabble analytics APIs}
  spec.summary       = %q{Heroku autoscaler}
  spec.homepage      = "http://github.com/harrystech/dynosaur"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "rspec-mocks"

  spec.add_dependency "heroku-api"
  spec.add_dependency 'google-api-client', "~> 0.6.4"
  spec.add_dependency 'librato-metrics'
  spec.add_dependency 'mail'
end
