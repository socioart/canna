module Authoriz
  class UnauthorizedError < StandardError
    attr_reader :reason, :action, :receiver, :args, :kwargs

    def initialize(reason, action, receiver, *args, **kwargs)
      @reason = reason
      @action = action
      @receiver = receiver
      @args = args
      @kwargs = kwargs
    end

    def message
      arguments = [
        action,
        receiver,
        *args,
      ].inspect
      arguments << kwargs.map {|k, v| ", #{k}: #{v.inspect}"}.join

      "Cannot #{arguments} because #{reason}"
    end
  end

  class Authorizer
    def can(action, receiver, *args, **kwargs, &block)
      true_or_reason = authorize(action, receiver, *args, **kwargs)
      Result.can(true_or_reason, &block)
    end

    def cannot(action, receiver, *args, **kwargs, &block)
      true_or_reason = authorize(action, receiver, *args, **kwargs)
      Result.cannot(true_or_reason, &block)
    end

    def can?(action, receiver, *args, **kwargs)
      authorize(action, receiver, *args, **kwargs) == true
    end

    def cannot?(action, receiver, *args, **kwargs)
      !can?(action, receiver, *args, **kwargs)
    end

    def authorize!(action, receiver, *args, **kwargs)
      true_or_reason = authorize(action, receiver, *args, **kwargs)
      return if true_or_reason == true

      raise UnauthorizedError.new(true_or_reason, action, receiver, *args, **kwargs)
    end

    private
    def authorize(action, receiver, *args, **kwargs, &block)
      receiver.send("authorize_to_#{action}", *args, **kwargs)
    end
  end
end
