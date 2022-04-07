# frozen_string_literal: true

require 'liquid'

require_relative 'json_filter'

Liquid::Template.register_filter(JsonFilter)
