module Canny
  class UnauthorizedError < StandardError
    attr_reader :reason, :action, :receiver, :args, :kwargs

    def initialize(reason, action, receiver, *args, **kwargs)
      @reason = reason
      @action = action
      @receiver = receiver
      @args = args
      @kwargs = kwargs
      super(build_message)
    end

    private
    def build_message
      arguments = [
        action,
        receiver,
        *args,
      ].inspect
      arguments << kwargs.map {|k, v| ", #{k}: #{v.inspect}" }.join

      "Cannot #{arguments} because #{reason}"
    end
  end

  class Authorizer
    attr_reader :default_args, :default_kwargs

    def initialize(*default_args, **default_kwargs)
      @default_args = default_args
      @default_kwargs = default_kwargs
    end

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

    # in ruby < 2.7, **{} passes empty hash as argument
    # https://www.ruby-lang.org/en/news/2019/12/12/separation-of-positional-and-keyword-arguments-in-ruby-3-0/#other-minor-changes-empty-hash
    if Gem::Version.new(RUBY_VERSION) < Gem::Version.new("2.7.0")
      def authorize(action, receiver, *args, **kwargs)
        args = default_args + args
        kwargs = default_kwargs.merge(kwargs)

        if kwargs.empty?
          receiver.send("authorize_to_#{action}", *args)
        else
          receiver.send("authorize_to_#{action}", *args, **kwargs)
        end
      end
    else
      def authorize(action, receiver, *args, **kwargs)
        args = default_args + args
        kwargs = default_kwargs.merge(kwargs)
        receiver.send("authorize_to_#{action}", *args, **kwargs)
      end
    end
  end
end
