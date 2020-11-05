# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'frise/version'

Gem::Specification.new do |spec|
  spec.name          = 'frise'
  spec.version       = Frise::VERSION
  spec.authors       = ['Velocidi']
  spec.email         = ['hello@velocidi.com']

  spec.summary       = 'Ruby config library with schema validation, default values and templating'
  spec.homepage      = 'https://github.com/velocidi/frise'
  spec.license       = 'Apache-2.0'

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features|example)/})
  end
  spec.require_paths = ['lib']
  spec.required_ruby_version = '>= 2.3.0'

  spec.add_dependency 'liquid', '~> 4.0'

  spec.add_development_dependency 'bundler', '~> 2.0'
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rspec', '~> 3.9'
  spec.add_development_dependency 'rubocop', '0.77.0'
  spec.add_development_dependency 'simplecov', '~> 0.18'
  spec.add_development_dependency 'simplecov-lcov', '0.8.0'
end
