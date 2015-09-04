# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'dynosaur/version'

Gem::Specification.new do |spec|
  spec.name          = "dynosaur"
  spec.version       = Dynosaur::VERSION
  spec.authors       = ["Andy O'Neill", "Pierre Jambet", "Daniel Schwartz"]
  spec.email         = ["aoneill@harrys.com",  'pjambet@harrys.com']
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
  spec.add_development_dependency "pry-byebug"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "rspec-mocks"
  spec.add_development_dependency "timecop"
  spec.add_development_dependency "faker"

  spec.add_dependency 'activesupport'
  spec.add_dependency "heroku-api" # We should remove that at some point and fully use platform API
  spec.add_dependency "platform-api"
  spec.add_dependency 'google-api-client', "~> 0.6.4"
  spec.add_dependency 'newrelic_api', "~> 1.2.4"
  spec.add_dependency 'activeresource'
  spec.add_dependency 'librato-metrics'
  spec.add_dependency 'aws-sdk-v1'  # for SES
  spec.add_dependency 'jwt', "~> 0.1.11"
end
