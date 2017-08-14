#!/usr/bin/env ruby

require 'frise/parser'
require 'set'

module Frise
  # Checks if a pre-loaded config object conforms to a schema file.
  #
  # The validate and validate_at static methods read schema files and validates config objects
  # against the parsed schema. They can optionally be initialized with a set of user-defined
  # validators that can be used in the schema files for custom validations.
  class Validator
    attr_reader :errors

    def initialize(root, validators = nil)
      @root = root
      @validators = validators
      @errors = []
    end

    def widened_class(obj)
      class_name = obj.class.to_s
      return 'Boolean' if %w[TrueClass FalseClass].include? class_name
      return 'Integer' if %w[Fixnum Bignum].include? class_name
      class_name
    end

    def add_validation_error(path, msg)
      logged_path = path.empty? ? '<root>' : path[1..-1]
      @errors << "At #{logged_path}: #{msg}"
    end

    def get_full_schema(schema)
      case schema
      when Hash then schema
      when Symbol then { type: 'Object', validate: schema }
      when Array then
        if schema.size == 1
          { type: 'Array', all: schema[0] }
        else
          (raise "Invalid schema: #{schema.inspect}")
        end
      when String then
        if schema.end_with?('?')
          { type: schema[0..-2], optional: true }
        else
          { type: schema }
        end
      else raise "Invalid schema: #{schema.inspect}"
      end
    end

    def validate_optional(full_schema, obj, path)
      if obj.nil?
        add_validation_error(path, 'missing required value') unless full_schema[:optional]
        return false
      end
      true
    end

    def get_expected_types(full_schema)
      type_key = full_schema.fetch(:type, 'Hash')
      allowed_types = %w[Hash Array String Integer Float Object]
      return [Object.const_get(type_key)] if allowed_types.include?(type_key)
      return [TrueClass, FalseClass] if type_key == 'Boolean'
      raise "Invalid expected type in schema: #{type_key}"
    end

    def validate_type(full_schema, obj, path)
      expected_types = get_expected_types(full_schema)
      unless expected_types.any? { |typ| obj.is_a?(typ) }
        type_key = full_schema.fetch(:type, 'Hash')
        add_validation_error(path, "expected #{type_key}, found #{widened_class(obj)}")
        return false
      end
      true
    end

    def validate_custom(full_schema, obj, path)
      if full_schema[:validate]
        begin
          @validators.method(full_schema[:validate]).call(@root, obj)
        rescue StandardError => ex
          add_validation_error(path, ex.message)
        end
      end
      true
    end

    def validate_spec_keys(full_schema, obj, path, processed_keys)
      full_schema.each do |spec_key, spec_value|
        next if spec_key.is_a?(Symbol)
        validate_object("#{path}.#{spec_key}", obj[spec_key], spec_value)
        processed_keys << spec_key
      end
      true
    end

    def validate_remaining_keys(full_schema, obj, path, processed_keys)
      expected_types = get_expected_types(full_schema)
      if expected_types.size == 1 && expected_types[0].ancestors.member?(Enumerable)
        hash = obj.is_a?(Hash) ? obj : Hash[obj.map.with_index { |x, i| [i, x] }]
        hash.each do |key, value|
          if full_schema[:all_keys] && !key.is_a?(Symbol)
            validate_object(path, key, full_schema[:all_keys])
          end

          next if processed_keys.member? key
          if full_schema[:all]
            validate_object("#{path}.#{key}", value, full_schema[:all])
          elsif !full_schema[:allow_unknown_keys]
            add_validation_error(path, "unknown key: #{key}")
          end
        end
      end
      true
    end

    def validate_object(path, obj, schema)
      full_schema = get_full_schema(schema)

      return unless validate_optional(full_schema, obj, path)
      return unless validate_type(full_schema, obj, path)
      return unless validate_custom(full_schema, obj, path)

      processed_keys = Set.new
      return unless validate_spec_keys(full_schema, obj, path, processed_keys)
      validate_remaining_keys(full_schema, obj, path, processed_keys)
    end

    def self.parse_symbols(obj)
      case obj
      when Array then obj.map { |e| parse_symbols(e) }
      when Hash then Hash[obj.map { |k, v| [parse_symbols(k), parse_symbols(v)] }]
      when String then obj.start_with?('$') ? obj[1..-1].to_sym : obj
      else obj
      end
    end

    def self.validate_obj(config, schema, options = {})
      validator = Validator.new(config, options[:validators])
      validator.validate_object('', config, schema)

      if validator.errors.any?
        if options[:print]
          puts "#{validator.errors.length} config error(s) found:"
          validator.errors.each do |error|
            puts " - #{error}"
          end
        end

        exit 1 if options[:fatal]
        raise ValidationError.new(validator.errors), 'Invalid configuration' if options[:raise_error]
      end
      validator.errors
    end

    def self.validate(config, schema_file, options = {})
      schema = parse_symbols(Parser.parse(schema_file) || { allow_unknown_keys: true })
      validate_obj(config, schema, options)
    end

    def self.validate_at(config, at_path, schema_file, options = {})
      schema = parse_symbols(Parser.parse(schema_file) || { allow_unknown_keys: true })
      at_path.reverse.each { |key| schema = { key => schema, :allow_unknown_keys => true } }
      validate_obj(config, schema, options)
    end
  end

  # An error resulting of the validation of a config. The list of errors can be inspected using the
  # errors method.
  class ValidationError < StandardError
    attr_reader :errors

    def initialize(errors)
      @errors = errors
    end
  end
end
