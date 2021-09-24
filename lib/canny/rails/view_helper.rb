require "forwardable"

module Canny
  module Rails
    module ViewHelper
      extend Forwardable

      def can(action, receiver, *args, **kwargs, &block)
        authorizer.can(action, receiver, current_user, *args, **kwargs, &block)
      end

      def cannot(action, receiver, *args, **kwargs, &block)
        authorizer.cannot(action, receiver, current_user, *args, **kwargs, &block)
      end

      def can?(action, receiver, *args, **kwargs)
        authorizer.can?(action, receiver, current_user, *args, **kwargs) == true
      end

      def cannot?(action, receiver, *args, **kwargs)
        authorizer.cannot?(action, receiver, current_user, *args, **kwargs) != true
      end
    end
  end
end
