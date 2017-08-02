require 'frise/defaults_loader'
require 'frise/parser'
require 'frise/validator'

module Frise
  # The entrypoint for loading configs from files according to the conventions defined for Frise.
  #
  # The load method loads a configuration file, merges it with the applicable defaults and validates
  # its schema. Other methods in Loader perform only parts of the process.
  class Loader
    def initialize(schema_load_paths: [], defaults_load_paths: [], pre_loaders: [], validators: nil)
      @schema_load_paths = schema_load_paths
      @defaults_load_paths = defaults_load_paths
      @pre_loaders = pre_loaders
      @validators = validators
    end

    def load(config_file, exit_on_fail = true, symbol_table = nil)
      config = Parser.parse(config_file, symbol_table)
      config_name = File.basename(config_file)

      @pre_loaders.each do |pre_loader|
        config = pre_loader.call(config)
      end

      config = merge_defaults(config, config_name)
      validate(config, config_name, exit_on_fail)
    end

    def merge_defaults(config, defaults_name, symbol_table = nil)
      merge_defaults_at(config, [], defaults_name, symbol_table)
    end

    def merge_defaults_at(config, at_path, defaults_name, symbol_table = nil)
      @defaults_load_paths.map do |defaults_dir|
        defaults_file = File.join(defaults_dir, defaults_name)
        config = DefaultsLoader.merge_defaults_at(
          config, at_path, defaults_file, symbol_table || config
        )
      end
      config
    end

    def validate(config, schema_name, exit_on_fail = true)
      validate_at(config, [], schema_name, exit_on_fail)
    end

    def validate_at(config, at_path, schema_name, exit_on_fail = true)
      @schema_load_paths.map do |schema_dir|
        schema_file = File.join(schema_dir, schema_name)
        Validator.validate_at(config, at_path, schema_file, @validators, exit_on_fail)
      end
      config
    end
  end
end
