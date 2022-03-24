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
        YAML.safe_load(parse_as_text(file, symbol_table), aliases: true) || {}
      end

      def parse_as_text(file, symbol_table = nil)
        return nil unless File.file? file
        content = File.read(file)
        content = Liquid::Template.parse(content).render with_internal_vars(file, symbol_table) if symbol_table
        content
      end

      private

      def with_internal_vars(file, symbol_table)
        symbol_table.merge('_file_dir' => File.expand_path(File.dirname(file)))
      end
    end
  end
end
