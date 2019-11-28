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

      # rubocop:disable Style/MethodMissingSuper
      def method_missing(method_name, *args, &block)
        __target_object__.send(method_name, *args, &block)
      end
      # rubocop:enable Style/MethodMissingSuper

      def respond_to_missing?(method_name, include_private = false)
        __target_object__.respond_to?(method_name, include_private)
      end
    end
  end
end
