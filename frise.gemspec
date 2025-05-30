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
  spec.required_ruby_version = '>= 3.2.0'

  spec.add_dependency 'base64', '~> 0.2'
  spec.add_dependency 'liquid', '~> 5'

  spec.metadata['rubygems_mfa_required'] = 'true'
end
