#!/usr/bin/env ruby

require 'frise/parser'
require 'set'

module Boolean; end
class TrueClass; include Boolean; end
class FalseClass; include Boolean; end

module Frise
  module Validator
    class << self
      def parse_symbols(obj)
        case obj
        when Array then obj.map { |e| parse_symbols(e) }
        when Hash then Hash[obj.map { |k, v| [parse_symbols(k), parse_symbols(v)] }]
        when String then obj.start_with?('$') ? obj[1..-1].to_sym : obj
        else obj
        end
      end

      def validation_error(path, msg)
        logged_path = path.empty? ? '<root>' : path[1..-1]
        "In #{logged_path}: #{msg}"
      end

      def validate_object(root, path, obj, schema, validators, errors)
        full_schema = case schema
                      when Hash then schema
                      when Symbol then { type: 'Object', validate: schema }
                      when Array then { type: 'Array', all: schema[0] }
                      when String then
                        if schema.end_with?('?')
                          { type: schema[0..-2], optional: true }
                        else
                          { type: schema }
                        end
                      else raise "Invalid schema: #{schema}"
                      end

        if obj.nil?
          errors << validation_error(path, 'Missing required value') unless full_schema[:optional]
          return
        end

        expected_type = Object.const_get(full_schema.fetch(:type, 'Hash'))
        unless obj.is_a?(expected_type)
          errors << validation_error(path, "Expected #{expected_type}, found #{obj.class}")
          return
        end

        if full_schema[:validate]
          begin
            validators.method(full_schema[:validate]).call(root, obj)
          rescue StandardError => ex
            errors << validation_error(path, ex.message)
          end
        end

        processed_keys = Set.new

        full_schema.each do |spec_key, spec_value|
          unless spec_key.is_a?(Symbol)
            validate_object(root, "#{path}.#{spec_key}", obj[spec_key], spec_value, validators, errors)
            processed_keys << spec_key
          end
        end

        return unless expected_type.ancestors.member?(Enumerable)
        hash = obj.is_a?(Hash) ? obj : Hash[obj.map.with_index { |x, i| [i, x] }]
        hash.each do |key, value|
          if full_schema[:all_keys] && !key.is_a?(Symbol)
            validate_object(root, path, key, full_schema[:all_keys], validators, errors)
          end

          next if processed_keys.member? key
          if full_schema[:all]
            validate_object(root, "#{path}.#{key}", value, full_schema[:all], validators, errors)
          elsif !full_schema[:allow_unknown_keys]
            errors << validation_error(path, "Unknown key: #{key}")
          end
        end
      end

      def validate(config, schema_file, validators = nil, exit_on_fail = true, root = config)
        schema = parse_symbols(Parser.parse(schema_file))

        error_messages = []
        validate_object(root, '', config, schema, validators, error_messages)

        unless error_messages.empty?
          puts "#{error_messages.length} config error(s) found:"
          error_messages.each do |error|
            puts " - #{error}"
          end
          exit 1 if exit_on_fail
        end
        error_messages
      end

      def validate_at(config, at_path, schema_file, validators = nil, exit_on_fail = true, root = config)
        return validate(config, schema_file, validators, exit_on_fail, root) if at_path.empty?
        key, rest_path = at_path[0], at_path.drop(1)
        validate_at(config[key], rest_path, schema_file, validators, exit_on_fail, root)
      end
    end
  end
end
