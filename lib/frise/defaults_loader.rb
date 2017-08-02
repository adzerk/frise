require 'frise/parser'

module Frise
  # Provides the logic for merging config defaults into pre-loaded configuration objects.
  #
  # The merge_defaults and merge_defaults_at entrypoint methods provide ways to read files with
  # defaults and apply them to configuration objects.
  module DefaultsLoader
    class << self
      def boolean?(obj)
        [true, false].include? obj
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

        elsif defaults.class != config.class && !(boolean?(defaults) && boolean?(config))
          raise "Cannot merge config #{config} (#{config.class}) with defaults #{defaults} (#{defaults.class})"

        else
          config
        end
      end

      def merge_defaults_obj_at(config, at_path, defaults)
        return merge_defaults_obj(config, defaults) if at_path.empty?
        key = at_path[0]
        rest_path = at_path.drop(1)
        config.merge(key => merge_defaults_obj_at(config[key], rest_path, defaults))
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
