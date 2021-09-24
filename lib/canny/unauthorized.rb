module Canny
  class Unauthorized < StandardError
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
end
