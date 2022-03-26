# frozen_string_literal: true

require 'frise/parser'

module Frise
  # Provides the logic for merging config defaults into pre-loaded configuration objects.
  #
  # The merge_defaults and merge_defaults_at entrypoint methods provide ways to read files with
  # defaults and apply them to configuration objects.
  class DefaultsLoader
    SYMBOLS = %w[$all $optional].freeze

    def initialize(
      include_sym: '$include',
      content_include_sym: '$content_include',
      schema_sym: '$schema',
      delete_sym: '$delete'
    )

      @include_sym = include_sym
      @content_include_sym = content_include_sym
      @schema_sym = schema_sym
      @delete_sym = delete_sym
    end

    # returns the config without the keys whose values are marked for removal
    def clear_delete_markers(config)
      case config
      when Hash
        config.each_with_object({}) do |(k, v), new_hash|
          if v.has_frise_delete_marker_value?
            new_hash[k] = v.delete_marker_value
          elsif !v.is_frise_delete_marker?(@delete_sym)
            new_hash[k] = clear_delete_markers(v)
          end
        end
      when Array
        config.each_with_object([]) do |elem, new_arr|
          if elem.has_frise_delete_marker_value?
            new_arr.push(elem.value)
          elsif !elem.is_frise_delete_marker?(@delete_sym)
            new_arr.push(clear_delete_markers(elem))
          end
        end
      else
        config
      end
    end

    # rubocop:disable Lint/DuplicateBranch
    def merge_defaults_obj(config, defaults)
      config_class = widened_class(config)
      defaults_class = widened_class(defaults)

      if defaults.nil?
        config

      elsif config.nil?
        if defaults_class != 'Hash' then defaults
        elsif defaults['$optional'] then nil
        else
          merge_defaults_obj({}, defaults)
        end

      elsif config.is_frise_delete_marker?(@delete_sym) || defaults.is_frise_delete_marker?(@delete_sym)
        config.set_frise_delete_marker(@delete_sym)

      elsif defaults_class == 'Array' && config_class == 'Array'
        defaults + config

      elsif defaults_class == 'Hash' && defaults['$all'] && config_class == 'Array'
        config.map { |elem| merge_defaults_obj(elem, defaults['$all']) }

      elsif defaults_class == 'Hash' && config_class == 'Hash'
        new_config = {}
        (config.keys + defaults.keys).uniq.each do |key|
          next if SYMBOLS.include?(key)
          new_config[key] = config[key]
          new_config[key] = merge_defaults_obj(new_config[key], defaults[key]) if defaults.key?(key)
          new_config[key] = merge_defaults_obj(new_config[key], defaults['$all']) unless new_config[key].nil?
          new_config.delete(key) if new_config[key].nil?
        end
        new_config

      elsif defaults_class != config_class
        raise "Cannot merge config #{config.inspect} (#{widened_class(config)}) " \
              "with default #{defaults.inspect} (#{widened_class(defaults)})"

      else
        config
      end
    end
    # rubocop:enable Lint/DuplicateBranch

    def merge_defaults_obj_at(config, at_path, defaults)
      at_path.reverse.each { |key| defaults = { key => defaults } }
      merge_defaults_obj(config, defaults)
    end

    def merge_defaults(config, defaults_file, symbol_table = config)
      defaults = Parser.parse(defaults_file, symbol_table) || {}
      merge_defaults_obj(config, defaults)
    end

    def merge_defaults_at(config, at_path, defaults_file, symbol_table = config)
      defaults = Parser.parse(defaults_file, symbol_table) || {}
      merge_defaults_obj_at(config, at_path, defaults)
    end

    private

    def widened_class(obj)
      class_name = obj.class.to_s
      return 'String' if class_name == 'Hash' && !obj[@content_include_sym].nil?
      return 'Boolean' if %w[TrueClass FalseClass].include? class_name
      return 'Integer' if %w[Fixnum Bignum].include? class_name
      class_name
    end
  end
end

# extensions to help merge configurations with delete markers
# rubocop:disable Naming/PredicateName
# rubocop:disable Naming/AccessorMethodName
class BasicObject
  attr_accessor :delete_marker_value

  def is_frise_delete_marker?(sym)
    self == sym || has_frise_delete_marker_value?
  end

  def has_frise_delete_marker_value?
    !@delete_marker_value.nil?
  end

  def set_frise_delete_marker(sym)
    if frozen?
      dup.set_frise_delete_marker(sym)
    else
      @delete_marker_value =
        if self == sym
          nil
        elsif has_frise_delete_marker_value?
          delete_marker_value
        else
          self
        end

      self
    end
  end
end
# rubocop:enable Naming/PredicateName
# rubocop:enable Naming/AccessorMethodName
