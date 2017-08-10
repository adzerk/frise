# Frise
[![Build Status](https://travis-ci.org/ShiftForward/frise.svg?branch=master)](https://travis-ci.org/ShiftForward/frise)
[![Coverage Status](https://coveralls.io/repos/github/ShiftForward/frise/badge.svg?branch=master)](https://coveralls.io/github/ShiftForward/frise?branch=master)

Frise is a library for loading configuration files as native Ruby structures. Besides reading and
parsing the files themselves, it also:

- Completes it with default values specified in another file or set of files;
- Interprets [Liquid](https://shopify.github.io/liquid) templates in configs and defaults;
- Validates the loaded config according to a schema file or set of files.

## Install

```
gem install frise
```

## Usage

### Basic configs

The simplest example would be to load [a simple configuration](example/config.yml) from a file:

```ruby
require 'frise'
require 'pp'

loader = Frise::Loader.new
loader.load('example/config.yml')
# => {"movies"=>
#     [{"title"=>"The Shawshank Redemption",
#       "year"=>1994,
#       "categories"=>["Crime", "Drama"],
#       "rating"=>9.3},
#      {"title"=>"The Godfather",
#       "year"=>1972,
#       "director"=>"Francis Ford Coppola",
#       "categories"=>["Crime", "Drama"],
#       "rating"=>9.2}]}
```

Currently Frise only supports YAML files, but it may support JSON and other formats in the future.

### Default values

By defining directories where the files with default values can be found (in this example,
[example/_defaults](example/_defaults)), Frise can handle its application internally on load time:

```ruby
loader = Frise::Loader.new(defaults_load_paths: ['example/_defaults'])
loader.load('example/config.yml')
# => {"movies"=>
#     [{"title"=>"The Shawshank Redemption",
#       "year"=>1994,
#       "categories"=>["Crime", "Drama"],
#       "rating"=>9.3,
#       "director"=>"N/A"},
#      {"title"=>"The Godfather",
#       "year"=>1972,
#       "director"=>"Francis Ford Coppola",
#       "categories"=>["Crime", "Drama"],
#       "rating"=>9.2}],
#    "ui"=>
#     {"default_movie"=>"The Shawshank Redemption",
#      "filter_from"=>1972,
#      "filter_to"=>1994}}
```

Note that files with default values follow exactly the same structure of the config file itself.
Special values such as `$all` allow users to define default values for all elements of an object or
array. Liquid templates are also used to define some defaults as a function of other objects of the
config.

### Schemas

Additionally, configuration files can also be validated against a schema. By specifying
`schema_load_paths`, users can provide directories where schema files such as
[example/_schemas/config.yml](example/_schemas/config.yml) can be found:

```ruby
loader = Frise::Loader.new(
  schema_load_paths: ['example/_schemas'],
  defaults_load_paths: ['example/_defaults'])

loader.load('example/config.yml')
# {"movies"=>
#   [{"title"=>"The Shawshank Redemption",
#     "year"=>1994,
#     "categories"=>["Crime", "Drama"],
#     "rating"=>9.3,
#     "director"=>"N/A"},
#    {"title"=>"The Godfather",
#     "year"=>1972,
#     "director"=>"Francis Ford Coppola",
#     "categories"=>["Crime", "Drama"],
#     "rating"=>9.2}],
#  "ui"=>
#   {"default_movie"=>"The Shawshank Redemption",
#    "filter_from"=>1972,
#    "filter_to"=>1994}}
```

If this config is loaded without the defaults instead, there are now required values that are
missing and Frise by default prints a summary of the errors and terminates the program:


```ruby
loader = Frise::Loader.new(schema_load_paths: ['example/_schemas'])

loader.load('example/config.yml')
# 2 config error(s) found:
#  - At movies.0.director: missing required value
#  - At ui: missing required value
```

Once more, the structure of the schema mimics the structure of the config itself, making it easy to
write schemas and to create a config scaffold from its schema later.

Users can check a whole range of properties in config values besides their type: optional values,
hashes with validated keys, hashes with unknown keys and even custom validations are also supported.
The [specification](spec/frise/validator_spec.rb) of the validator provides various examples of
schemas and describes the behavior of each value (more documentation will be written soon).

### Other features

Users can also define custom code to be run before defaults and schemas are applied and can even do
each of the steps separately. Additionally, defaults and schemas can be loaded at a specific path
inside an existing Ruby object. The [Loader](lib/frise/loader.rb) class provides high-level methods
to access those features, while lower-level functionality can be accessed through
[Parser](lib/frise/parser.rb), [DefaultsLoader](lib/frise/defaults_loader.rb) and
[Validator](lib/frise/validator.rb).
