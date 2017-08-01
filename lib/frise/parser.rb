require 'yaml'

module Frise
  module Parser
    class << self
      def parse(file, symbol_table = nil)
        return {} unless File.file? file
        content = File.open(file).read
        content = Liquid::Template.parse(content).render symbol_table if symbol_table
        YAML.load(content) || {}
      end
    end
  end
end
