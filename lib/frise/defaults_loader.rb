require 'frise/parser'

module Frise
  # Provides the logic for merging config defaults into pre-loaded configuration objects.
  #
  # The merge_defaults and merge_defaults_at entrypoint methods provide ways to read files with
  # defaults and apply them to configuration objects.
  module DefaultsLoader
    class << self
      def widened_class(obj)
        class_name = obj.class.to_s
        return 'Boolean' if %w[TrueClass FalseClass].include? class_name
        return 'Integer' if %w[Fixnum Bignum].include? class_name
        class_name
      end

      def merge_defaults_obj(config, defaults)
        if defaults.nil?
          config

        elsif config.nil?
          if defaults.class != Hash then defaults
          elsif defaults['$optional'] then nil
          else merge_defaults_obj({}, defaults)
          end

        elsif defaults.class == Array && config.class == Array
          defaults + config

        elsif defaults.class == Hash && defaults['$all'] && config.class == Array
          config.map { |elem| merge_defaults_obj(elem, defaults['$all']) }

        elsif defaults.class == Hash && config.class == Hash
          new_config = {}
          (config.keys + defaults.keys).uniq.each do |key|
            next if key.start_with?('$')
            new_config[key] = config[key]
            new_config[key] = merge_defaults_obj(new_config[key], defaults[key]) if defaults.key?(key)
            new_config[key] = merge_defaults_obj(new_config[key], defaults['$all']) unless new_config[key].nil?
            new_config.delete(key) if new_config[key].nil?
          end
          new_config

        elsif widened_class(defaults) != widened_class(config)
          raise "Cannot merge config #{config.inspect} (#{widened_class(config)}) " \
            "with default #{defaults.inspect} (#{widened_class(defaults)})"

        else
          config
        end
      end

      def merge_defaults_obj_at(config, at_path, defaults)
        at_path.reverse.each { |key| defaults = { key => defaults } }
        merge_defaults_obj(config, defaults)
      end

      def merge_defaults(config, defaults_file, symbol_table = config)
        defaults = Parser.parse(defaults_file, symbol_table)
        merge_defaults_obj(config, defaults)
      end

      def merge_defaults_at(config, at_path, defaults_file, symbol_table = config)
        defaults = Parser.parse(defaults_file, symbol_table)
        merge_defaults_obj_at(config, at_path, defaults)
      end
    end
  end
end
