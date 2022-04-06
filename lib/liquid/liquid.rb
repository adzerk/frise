# frozen_string_literal: true

require 'liquid'

require_relative 'json_filter'
require_relative 'json_string_filter'

Liquid::Template.register_filter(JsonFilter)
Liquid::Template.register_filter(JsonStringFilter)
