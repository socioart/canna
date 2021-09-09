module Authoriz
  module Rails
    module ControllerAdditions
      module ClassMethods
      end

      module InstanceMethods
        def authorize!(action, receiver, *args, **kwargs)
          authorizer.authorize!(action, receiver, current_user, *args, **kwargs)
        end

        def authorizer
          @authorizer ||= Authorizer.new
        end
      end
    end
  end
end
