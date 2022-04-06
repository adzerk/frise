# frozen_string_literal: true

require 'json'

# Converts a variable into its JSON representation safely escaped to be used inside a string
module JsonStringFilter
  def json_string(object)
    JSON.dump(object).inspect[1..-2]
  end
end
