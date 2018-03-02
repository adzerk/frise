lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'frise/version'

Gem::Specification.new do |spec|
  spec.name          = 'frise'
  spec.version       = Frise::VERSION
  spec.authors       = ['ShiftForward']
  spec.email         = ['info@shiftforward.eu']

  spec.summary       = 'Ruby config library with schema validation, default values and templating'
  spec.homepage      = 'https://github.com/ShiftForward/frise'
  spec.license       = 'Apache-2.0'

  spec.files         = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features|example)/})
  end
  spec.require_paths = ['lib']
  spec.required_ruby_version = '>= 2.1.0'

  spec.add_dependency 'liquid', '~> 3.0'

  spec.add_development_dependency 'bundler', '~> 1.14'
  spec.add_development_dependency 'coveralls', '~> 0.8.21'
  spec.add_development_dependency 'rake', '~> 12.3'
  spec.add_development_dependency 'rspec', '~> 3.4'
  spec.add_development_dependency 'rubocop', '~> 0.53.0'
  spec.add_development_dependency 'simplecov', '~> 0.14.1'
end
