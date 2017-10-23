# frozen_string_literal: true

$LOAD_PATH.push File.expand_path('../lib', __FILE__)
require 'mindex/version'

Gem::Specification.new do |spec|
  spec.name          = 'mindex'
  spec.version       = Mindex::VERSION
  spec.authors       = ['Michael Voigt']
  spec.email         = ['michael.voigt@spider-network.com']
  spec.summary       = 'Mindex provides helper methods to manage your elasticsearch indices'
  spec.homepage      = 'http://www.spider-network.com'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(spec)/})
  spec.require_paths = ['lib']

  spec.add_dependency 'elasticsearch'
  spec.add_dependency 'activesupport'
  spec.add_dependency 'dry-validation'

  spec.add_development_dependency 'bundler', '> 1'
  spec.add_development_dependency 'rake'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'pry'
  spec.add_development_dependency 'rubocop'
  spec.add_development_dependency 'rubocop-rspec'
  spec.add_development_dependency 'sequel'
  spec.add_development_dependency 'sqlite3'
end
