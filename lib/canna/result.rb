module Canna
  class Result
    class << self
      def can(true_or_reason, &block_for_can)
        result = new(:can, true_or_reason)
        block_for_can ? result.run(&block_for_can) : result
      end

      def cannot(true_or_reason, &block_for_cannot)
        result = new(:cannot, true_or_reason)
        block_for_cannot ? result.run(&block_for_cannot) : result
      end

      private :new
    end

    attr_reader :reason, :type, :value

    def initialize(type, true_or_reason)
      @type = type
      @authorized = true_or_reason == true
      @reason = true_or_reason unless authorized?
      @run_called = false
      @else_called = false
    end

    def authorized?
      @authorized
    end

    def run(&block)
      raise ArgumentError, "#{self.class}#run requires block" unless block_given?
      raise "#{self.class}#run cannot call twice" if @run_called

      @run_called = true

      case
      when type == :can && authorized?
        @value = block.call
      when type == :cannot && !authorized?
        @value = block.call(reason)
      end

      self
    end

    def else(&block)
      raise ArgumentError, "#{self.class}#else requires block" unless block_given?
      raise "#{self.class}#else cannot call twice" if @else_called

      @else_called = true

      case
      when type == :can && !authorized?
        @value = block.call(reason)
      when type == :cannot && authorized?
        @value = block.call
      end
      self
    end
  end
end
