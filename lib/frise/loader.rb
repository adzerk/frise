require 'frise/defaults_loader'
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

    def validate_config(root, config, schema_file, exit_on_fail = false)
      error_messages = Validator.validate_config(root, config, schema_file, @validators)
      unless error_messages.empty?
        puts "#{error_messages.length} config error(s) found:"
        error_messages.each do |error|
          puts " - #{error}"
        end
        exit 1 if exit_on_fail
      end
      error_messages
    end

    def load_config(config_file, exit_on_fail = true)
      config = YAML.load_file(config_file) || {}

      @pre_loaders.each do |pre_loader|
        config = pre_loader.call(config)
      end

      @defaults_load_paths.each do |defaults_dir|
        defaults_file = File.join(defaults_dir, File.basename(config_file))
        config = DefaultsLoader.merge_defaults(config, defaults_file)
      end

      @schema_load_paths.each do |schema_dir|
        schema_file = File.join(schema_dir, File.basename(config_file))
        validate_config(config, config, schema_file, exit_on_fail)
      end

      config
    end
  end
end
