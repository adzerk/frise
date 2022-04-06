# frozen_string_literal: true

require 'json'

# Converts a variable into its JSON representation
module JsonFilter
  def json(object)
    JSON.dump(object)
  end
end
