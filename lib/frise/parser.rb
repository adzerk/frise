# frozen_string_literal: true

require 'liquid'
require 'yaml'

module Frise
  # Provides a static parse method for reading a config from a YAML file applying the required
  # transformations.
  module Parser
    class << self
      def parse(file, symbol_table = nil)
        return nil unless File.file? file
        content = File.open(file).read
        content = Liquid::Template.parse(content).render with_internal_vars(file, symbol_table) if symbol_table
        YAML.safe_load(content, [], [], true) || {}
      end

      private

      def with_internal_vars(file, symbol_table)
        symbol_table.merge('_file_dir' => File.dirname(file))
      end
    end
  end
end
