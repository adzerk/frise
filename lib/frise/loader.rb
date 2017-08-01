require 'frise/defaults_loader'
require 'frise/parser'
require 'frise/validator'
require 'yaml'

module Frise
  class Loader
    def initialize(schema_load_paths: [], defaults_load_paths: [], pre_loaders: [], validators: nil)
      @schema_load_paths = schema_load_paths
      @defaults_load_paths = defaults_load_paths
      @pre_loaders = pre_loaders
      @validators = validators
      @overrides = {}
    end

    def load(config_file, exit_on_fail = true, symbol_table = nil)
      config = Parser.parse(config_file, symbol_table)

      @pre_loaders.each do |pre_loader|
        config = pre_loader.call(config)
      end

      defaults_files = @defaults_load_paths.map do |defaults_dir|
        File.join(defaults_dir, File.basename(config_file))
      end

      schema_files = @schema_load_paths.map do |schema_dir|
        File.join(schema_dir, File.basename(config_file))
      end

      config = merge_defaults(config, defaults_files, symbol_table)
      validate(config, schema_files, exit_on_fail)
    end

    def merge_defaults(config, defaults_files, symbol_table = nil)
      defaults_files.each do |defaults_file|
        config = DefaultsLoader.merge_defaults(config, defaults_file, symbol_table || config)
      end
      config
    end

    def validate(config, schema_files, exit_on_fail = true)
      schema_files.each do |schema_file|
        Validator.validate(config, schema_file, @validators, exit_on_fail)
      end
      config
    end
  end
end
