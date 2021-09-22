require "action_controller"

module Canna
  module Rails
    module ControllerHelper
      module ClassMethods
        # class UsersController
        #   authorize_action # adds before_action does `authorize! :new, User` etc. and `authorize! :show, @user` etc.
        # end
        #
        # class CurrentUser::AvatarsController
        #   authorize_action class_name: "User::Avatar", instance_name: "current_user_avatar" # adds before_action does `authorize! :new, User::Avatar` etc. and `authorize! :show, @current_user_avatar` etc.
        # end
        #
        # class Project::DocumentsController
        #   # add args to authorize_to_* methods
        #   authorize_action class_args: -> { [] }, class_kwargs: -> { {project: @project} }, instance_args: -> { [] }, instance_kwargs: -> { {} }
        # end
        #
        # class Project::DocumentsController
        #   # manually authorization (ignore arguments without :only, :except)
        #   authorize_action do |action|
        #     case action
        #     in :new | :create
        #       authorize! action, Project::Document, project: @project
        #     else
        #       authorize! action, @document
        #     end
        #   end
        # end
        #
        # @param only [Array<Symbol>, Array<String>]
        # @param except [Array<Symbol>, Array<String>]
        # @param class_name [String]
        # @param instance_name [String]
        # @param class_args [nil, Proc -> Array]
        # @param class_kwargs [nil, Proc -> Hash]
        # @param instance_args [nil, Proc -> Array]
        # @param instance_kwargs [nil, Proc -> Hash]
        # rubocop:disable Metrics/ParameterLists
        def authorize_action(
          only: nil,
          except: nil,
          class_name: nil,
          instance_name: nil,
          class_args: nil,
          class_kwargs: nil,
          instance_args: nil,
          instance_kwargs: nil,
          &block
        )
          if block_given?
            before_action(only: only, except: except) do
              authorize_action!(&block)
            end
            return
          end

          class_name ||= name.gsub(/Controller$/, "").singularize
          klass = const_get(class_name)
          instance_name ||= klass.model_name.element

          before_action(only: only, except: except) do
            authorize_action!(
              klass,
              instance_name,
              class_args: class_args,
              class_kwargs: class_kwargs,
              instance_args: instance_args,
              instance_kwargs: instance_kwargs,
            )
          end
        end
        # rubocop:enable Metrics/ParameterLists
      end

      module InstanceMethods
        private
        # @param action [Symbol]
        # @param receiver [Object]
        # @param args [Array]
        # @param kwargs [Hash]
        def authorize!(action, receiver, *args, **kwargs)
          authorizer.authorize!(action, receiver, current_user, *args, **kwargs)
        end

        # @param klass [Class]
        # @param instance_name [String]
        # @param class_args [nil, Proc -> Array]
        # @param class_kwargs [nil, Proc -> Hash]
        # @param instance_args [nil, Proc -> Array]
        # @param instance_kwargs [nil, Proc -> Hash]
        # rubocop:disable Metrics/ParameterLists
        def authorize_action!(
          klass = nil,
          instance_name = nil,
          class_args: nil,
          class_kwargs: nil,
          instance_args: nil,
          instance_kwargs: nil,
          &block
        )
          action = action_name.to_sym
          return instance_exec(action, &block) if block_given?

          if actions_for_class.include?(action)
            receiver = klass
            args = class_args ? instance_exec(&class_args) : []
            kwargs = class_kwargs ? instance_exec(&class_kwargs) : {}
          else
            receiver = instance_variable_get("@#{instance_name}")
            args = instance_args ? instance_exec(&instance_args) : []
            kwargs = instance_kwargs ? instance_exec(&instance_kwargs) : {}
          end

          authorize!(action, receiver, *args, **kwargs)
        end
        # rubocop:enable Metrics/ParameterLists

        # @return [Authorizer]
        def authorizer
          @authorizer ||= Authorizer.new
        end

        # @return [Set<Symbol>]
        def actions_for_class
          @actions_for_class ||= Set.new(%i(index new create))
        end
      end

      def self.included(klass)
        klass.extend ClassMethods
        klass.include InstanceMethods
      end
    end
  end
end
