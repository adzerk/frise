# frozen_string_literal: true

require 'frise/defaults_loader'
require 'frise/loader/lazy'
require 'frise/parser'
require 'frise/validator'

module Frise
  # The entrypoint for loading configs from files according to the conventions defined for Frise.
  #
  # The load method loads a configuration file, merges the applicable includes and validates its schema.
  class Loader
    def initialize(include_sym: '$include',
                   content_include_sym: '$content_include',
                   schema_sym: '$schema',
                   delete_sym: '$delete',
                   pre_loaders: [],
                   validators: nil,
                   exit_on_fail: true)

      @include_sym = include_sym
      @content_include_sym = content_include_sym
      @schema_sym = schema_sym
      @delete_sym = delete_sym
      @pre_loaders = pre_loaders
      @validators = validators
      @exit_on_fail = exit_on_fail

      @defaults_loader = DefaultsLoader.new(
        include_sym: include_sym,
        content_include_sym: content_include_sym,
        schema_sym: schema_sym,
        delete_sym: delete_sym
      )
    end

    def load(config_file, global_vars = {})
      config = Parser.parse(config_file, global_vars)
      return nil unless config

      @pre_loaders.each do |pre_loader|
        config = pre_loader.call(config)
      end

      config = process_includes(config, [], config, global_vars) unless @include_sym.nil?
      config = process_schemas(config, [], global_vars) unless @schema_sym.nil?
      config
    end

    private

    def process_includes(config, at_path, root_config, global_vars, include_confs_stack = [])
      return config unless config.instance_of?(Hash)

      # process $content_include directives
      config, content_include_confs = extract_content_include(config, at_path)
      unless content_include_confs.empty?
        raise "At #{build_path(at_path)}: a #{@content_include_sym} must not have any sibling key" unless config.empty?

        content = ''
        content_include_confs.each do |include_conf|
          symbol_table = build_symbol_table(root_config, at_path, nil, global_vars, include_conf)
          content += Parser.parse_as_text(include_conf['file'], symbol_table) || ''
        end
        return content
      end

      # process $include directives
      config, next_include_confs = extract_include(config, at_path)
      include_confs = next_include_confs + include_confs_stack
      res = if include_confs.empty?
              config.to_h { |k, v| [k, process_includes(v, at_path + [k], root_config, global_vars)] }
            else
              Lazy.new do
                include_conf = include_confs.first
                rest_include_confs = include_confs[1..]
                symbol_table = build_symbol_table(root_config, at_path, config, global_vars, include_conf)
                included_config = Parser.parse(include_conf['file'], symbol_table)
                config = @defaults_loader.merge_defaults_obj(config, included_config)
                process_includes(config, at_path, merge_at(root_config, at_path, config), global_vars,
                                 rest_include_confs)
              end
            end
      @delete_sym.nil? ? res : omit_deleted(res)
    end

    def process_schema_includes(schema, at_path, global_vars)
      return schema unless schema.instance_of?(Hash)

      schema, included_schemas = extract_include(schema, at_path)
      if included_schemas.empty?
        schema.to_h { |k, v| [k, process_schema_includes(v, at_path + [k], global_vars)] }
      else
        included_schemas.each do |defaults_conf|
          schema = Parser.parse(defaults_conf['file'], global_vars).merge(schema)
        end
        process_schema_includes(schema, at_path, global_vars)
      end
    end

    def process_schemas(config, at_path, global_vars)
      return config unless config.instance_of?(Hash)

      config = config.to_h do |k, v|
        new_v = process_schemas(v, at_path + [k], global_vars)
        return nil if !v.nil? && new_v.nil?
        [k, new_v]
      end

      config, schema_files = extract_schema(config, at_path)
      schema_files.each do |schema_file|
        schema = Parser.parse(schema_file, global_vars)
        schema = process_schema_includes(schema, at_path, global_vars)

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

    def extract_schema(config, at_path)
      extract_special(config, @schema_sym, at_path) do |value|
        case value
        when String then value
        else raise "At #{build_path(at_path)}: illegal value for a #{@schema_sym} element: #{value.inspect}"
        end
      end
    end

    def extract_include(config, at_path)
      extract_include_base(config, @include_sym, at_path)
    end

    def extract_content_include(config, at_path)
      extract_include_base(config, @content_include_sym, at_path)
    end

    def extract_include_base(config, sym, at_path)
      extract_special(config, sym, at_path) do |value|
        case value
        when Hash then value
        when String then { 'file' => value }
        else raise "At #{build_path(at_path)}: illegal value for a #{sym} element: #{value.inspect}"
        end
      end
    end

    def extract_special(config, key, at_path, &block)
      case config[key]
      when nil then [config, []]
      when Array then [config.reject { |k| k == key }, config[key].map(&block)]
      else raise "At #{build_path(at_path)}: illegal value for #{key}: #{config[key].inspect}"
      end
    end

    # merges the `to_merge` value on `config` at path `at_path`
    def merge_at(config, at_path, to_merge)
      return config.merge(to_merge) if at_path.empty?
      head, *tail = at_path
      config.merge(head => merge_at(config[head], tail, to_merge))
    end

    # returns the config without the keys whose values are @delete_sym
    # @delete_sym given as array elements are not handled.
    def omit_deleted(config)
      config.each_with_object({}) do |(k, v), new_hash|
        if v.is_a?(Hash)
          new_hash[k] = omit_deleted(v)
        else
          new_hash[k] = v unless v == @delete_sym
        end
      end
    end

    # builds the symbol table for the Liquid renderization of a file, based on:
    #   - `root_config`: the root of the whole config
    #   - `at_path`: the current path
    #   - `config`: the config subtree being built
    #   - `global_vars`: the global variables
    #   - `include_conf`: the $include or $content_include configuration
    def build_symbol_table(root_config, at_path, config, global_vars, include_conf)
      extra_vars = (include_conf['vars'] || {}).transform_values { |v| root_config.dig(*v.split('.')) }
      extra_consts = include_conf['constants'] || {}

      omit_deleted(config ? merge_at(root_config, at_path, config) : root_config)
        .merge(global_vars)
        .merge(extra_vars)
        .merge(extra_consts)
        .merge('_this' => config)
    end

    # builds a user-friendly string indicating a path
    def build_path(at_path)
      at_path.empty? ? '<root>' : at_path.join('.')
    end
  end
end
