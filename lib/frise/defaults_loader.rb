require 'liquid'

class Object
  def boolean?
    is_a?(TrueClass) || is_a?(FalseClass)
  end
end

module Frise
  module DefaultsLoader
    class << self
      def deep_merge_defaults(config, defaults)
        if defaults.nil?
          config

        elsif config.nil?
          if defaults.class != Hash then defaults
          elsif defaults['$optional'] then nil
          else deep_merge_defaults({}, defaults)
          end

        elsif defaults.class == Array && config.class == Array
          defaults + config

        elsif defaults.class == Hash && defaults['$all'] && config.class == Array
          config.map { |elem| deep_merge_defaults(elem, defaults['$all']) }

        elsif defaults.class == Hash && config.class == Hash
          new_config = {}
          (config.keys + defaults.keys).uniq.each do |key|
            next if key.start_with?('$')
            new_config[key] = config[key]
            new_config[key] = deep_merge_defaults(new_config[key], defaults[key]) if defaults.key?(key)
            new_config[key] = deep_merge_defaults(new_config[key], defaults['$all']) unless new_config[key].nil?
            new_config.delete(key) if new_config[key].nil?
          end
          new_config

        elsif defaults.class != config.class && !(defaults.boolean? && config.boolean?)
          raise "Cannot merge config #{config} (#{config.class}) with defaults #{defaults} (#{defaults.class})"

        else
          config
        end
      end

      def merge_defaults(config, defaults_file, render_config: nil)
        if File.file? defaults_file
          defaults_template = File.open(defaults_file).read
          defaults_str =
            Liquid::Template.parse(defaults_template).render (render_config || config)
          deep_merge_defaults(config, YAML.load(defaults_str) || {})
        else
          config
        end
      end
    end
  end
end
