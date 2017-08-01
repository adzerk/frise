# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'frise/version'

Gem::Specification.new do |spec|
  spec.name          = 'frise'
  spec.version       = Frise::VERSION
  spec.authors       = ['ShiftForward']
  spec.email         = ['info@shiftforward.eu']

  spec.summary       = 'A config loading library.'
  spec.description   = 'falta fazer'
  spec.homepage      = 'https://github.com/ShiftForward/frise'
  spec.license       = 'Apache-2.0'

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end
  spec.require_paths = ['lib']
  spec.required_ruby_version = '>= 2.0.0'

  spec.add_dependency 'liquid', '~> 3.0'

  spec.add_development_dependency 'bundler', '~> 1.14'
  spec.add_development_dependency 'rake', '~> 10.0'
end
