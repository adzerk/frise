# frozen_string_literal: true

require 'frise/defaults_loader'
require 'frise/loader/lazy'
require 'frise/parser'
require 'frise/validator'

module Frise
  # The entrypoint for loading configs from files according to the conventions defined for Frise.
  #
  # The load method loads a configuration file, merges it with the applicable defaults and validates
  # its schema. Other methods in Loader perform only parts of the process.
  class Loader
    def initialize(include_sym: '$include', schema_sym: '$schema', pre_loaders: [], validators: nil, exit_on_fail: true)
      @include_sym = include_sym
      @schema_sym = schema_sym
      @pre_loaders = pre_loaders
      @validators = validators
      @exit_on_fail = exit_on_fail
    end

    def load(config_file, global_vars = {})
      config = Parser.parse(config_file, global_vars)
      return nil unless config

      @pre_loaders.each do |pre_loader|
        config = pre_loader.call(config)
      end

      config = process_includes(config, [], config, global_vars) if @include_sym
      config = process_schemas(config, [], global_vars) if @schema_sym
      config
    end

    private

    def process_includes(config, at_path, root_config, global_vars)
      return config unless config.class == Hash

      config, defaults_confs = extract_include(config)
      if defaults_confs.empty?
        config.map { |k, v| [k, process_includes(v, at_path + [k], root_config, global_vars)] }.to_h
      else
        Lazy.new do
          defaults_confs.each do |defaults_conf|
            extra_vars = (defaults_conf['vars'] || {}).map { |k, v| [k, root_config.dig(*v.split('.'))] }.to_h
            extra_consts = defaults_conf['constants'] || {}
            symbol_table = merge_at(root_config, at_path, config)
                           .merge(global_vars).merge(extra_vars).merge(extra_consts).merge('_this' => config)

            config = DefaultsLoader.merge_defaults_obj(config, Parser.parse(defaults_conf['file'], symbol_table))
          end
          process_includes(config, at_path, merge_at(root_config, at_path, config), global_vars)
        end
      end
    end

    def process_schema_includes(schema, global_vars)
      return schema unless schema.class == Hash

      schema, included_schemas = extract_include(schema)
      if included_schemas.empty?
        schema.map { |k, v| [k, process_schema_includes(v, global_vars)] }.to_h
      else
        included_schemas.each do |defaults_conf|
          schema = Parser.parse(defaults_conf['file'], global_vars).merge(schema)
        end
        process_schema_includes(schema, global_vars)
      end
    end

    def process_schemas(config, at_path, global_vars)
      return config unless config.class == Hash

      config = config.map do |k, v|
        new_v = process_schemas(v, at_path + [k], global_vars)
        return nil if !v.nil? && new_v.nil?
        [k, new_v]
      end.to_h

      config, schema_files = extract_schema(config)
      schema_files.each do |schema_file|
        schema = Parser.parse(schema_file, global_vars)
        schema = process_schema_includes(schema, global_vars)

        errors = Validator.validate_obj(config,
                                        schema,
                                        path_prefix: at_path,
                                        validators: @validators,
                                        print: @exit_on_fail,
                                        fatal: @exit_on_fail)
        return nil if errors.any?
      end
      config
    end

    def extract_schema(config)
      extract_special(config, @schema_sym) do |value|
        case value
        when String then value
        else raise "Illegal value for a #{@schema_sym} element: #{value.inspect}"
        end
      end
    end

    def extract_include(config)
      extract_special(config, @include_sym) do |value|
        case value
        when Hash then value
        when String then { 'file' => value }
        else raise "Illegal value for a #{@include_sym} element: #{value.inspect}"
        end
      end
    end

    def extract_special(config, key)
      case config[key]
      when nil then [config, []]
      when Array then [config.reject { |k| k == key }, config[key].map { |e| yield e }]
      else raise "Illegal value for #{key}: #{config[key].inspect}"
      end
    end

    def merge_at(config, at_path, to_merge)
      return config.merge(to_merge) if at_path.empty?
      head, *tail = at_path
      config.merge(head => merge_at(config[head], tail, to_merge))
    end
  end
end
