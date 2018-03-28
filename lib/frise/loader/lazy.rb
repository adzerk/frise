# frozen_string_literal: true

module Frise
  class Loader
    # A basic proxy object.
    class Lazy < BasicObject
      def initialize(&callable)
        @callable = callable
      end

      def __target_object__
        @__target_object__ ||= @callable.call
      end

      # rubocop:disable Style/MethodMissing
      def method_missing(method_name, *args, &block)
        __target_object__.send(method_name, *args, &block)
      end
      # rubocop:enable Style/MethodMissing
    end
  end
end
