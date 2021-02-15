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
    def clear_deleted_markers(config)
        if config.is_a?(Hash)
          config.each_with_object({}) do |(k, v), new_hash|
            if v.instance_of?(Frise::DefaultsLoader::DeleteMarker)
              new_hash[k] = v.value unless v.value.nil?
            elsif v != @delete_sym
              new_hash[k] = clear_deleted_markers(v)
            end
          end
        elsif config.is_a?(Array)
          config.each_with_object([]) do |elem, new_arr|
            if elem.instance_of?(Frise::DefaultsLoader::DeleteMarker)
              new_arr.push(elem.value) unless v.value.nil?
            elsif elem != @delete_sym
              new_arr.push(clear_deleted_markers(elem))
            end
          end
        else
          config
        end
    end

    def widened_class(obj)
      class_name = obj.class.to_s
      return 'String' if class_name == 'Hash' && !obj[@content_include_sym].nil?
      return 'Boolean' if %w[TrueClass FalseClass].include? class_name
      return 'Integer' if %w[Fixnum Bignum].include? class_name
      class_name
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
        else merge_defaults_obj({}, defaults)
        end

      elsif config == @delete_sym || defaults == @delete_sym || config_class == "Frise::DefaultsLoader::DeleteMarker" || defaults_class == "Frise::DefaultsLoader::DeleteMarker"
        DeleteMarker.new(@delete_sym, config)

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

    class DeleteMarker
      attr_accessor :value

      def initialize(delete_sym, left)
        @delete_sym = delete_sym

        if left === delete_sym
          @value = nil
        elsif left.instance_of?(DeleteMarker)
          @value = left.value
        else
          @value = left
        end
      end

      def to_s
        if @value.nil?
          @delete_sym.to_s
        else
          @value.to_s
        end
      end
    end
  end
end
