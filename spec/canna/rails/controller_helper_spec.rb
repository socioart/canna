require "spec_helper"
require "canna/rails"

module Canna
  module Rails
    RSpec.describe ControllerHelper do
      let(:controller_class) do
        Class.new(ActionController::Base) do
          include ControllerHelper

          def index
            head :ok
          end

          def show
            head :ok
          end
        end
      end

      let(:controller) { controller_class.new }

      let(:model_class) {
        Class.new
      }
      let(:model) { model_class.new }

      let(:request) {
        req = ActionDispatch::TestRequest.create
        req
      }
      let(:response) { ActionDispatch::Response.create }
      let(:current_user) { double(:current_user) }

      before do
        allow(controller).to receive(:current_user).and_return(current_user)
      end

      describe ".authorize_action" do
        context "with no arguments" do
          before do
            allow(controller_class).to receive(:name).and_return("Project::DocumentsController")
            allow(controller_class).to receive(:const_get).with("Project::Document").and_return(model_class)

            model_name = double(:model_name)
            allow(model_name).to receive(:element).and_return("document")
            allow(model_class).to receive(:model_name).and_return(model_name)

            controller_class.class_eval do
              authorize_action
            end
          end

          it "call before_action to call authorize_action! with default class and instance name" do
            expect(controller).to receive(:authorize_action!).with(
              model_class,
              "document",
              class_args: nil,
              class_kwargs: nil,
              instance_args: nil,
              instance_kwargs: nil,
            )
            request.action = "index"
            controller.dispatch(:index, request, response)
          end
        end

        context "with block" do
          let(:block) { -> {} }

          before do
            b = block
            controller_class.class_eval do
              authorize_action(&b)
            end
          end

          it "call before_action to call authorize_action! with specified block" do
            block_for_instance = nil
            expect(controller).to(receive(:authorize_action!).with(no_args) {|&b| block_for_instance = b })

            request.action = "index"
            controller.dispatch(:index, request, response)

            expect(block_for_instance).to eq block
          end
        end

        context "with class_name, instance_name" do
          let(:foo_class) { Class.new }

          before do
            allow(controller_class).to receive(:const_get).with("Foo").and_return(foo_class)
            controller_class.class_eval do
              authorize_action class_name: "Foo", instance_name: "bar"
            end
          end

          it "call before_action to call authorize_action! with specified class and instance name" do
            expect(controller).to receive(:authorize_action!).with(
              foo_class,
              "bar",
              class_args: nil,
              class_kwargs: nil,
              instance_args: nil,
              instance_kwargs: nil,
            )
            request.action = "index"
            controller.dispatch(:index, request, response)
          end
        end

        context "with (class|instance)_(args|kwargs)" do
          let(:class_args) { -> {} }
          let(:class_kwargs) { -> {} }
          let(:instance_args) { -> {} }
          let(:instance_kwargs) { -> {} }
          before do
            allow(controller_class).to receive(:const_get).with("Project::Document").and_return(model_class)

            c_args = class_args
            c_kwargs = class_kwargs
            i_args = instance_args
            i_kwargs = instance_kwargs

            controller_class.class_eval do
              authorize_action(
                class_name: "Project::Document",
                instance_name: "document",
                class_args: c_args,
                class_kwargs: c_kwargs,
                instance_args: i_args,
                instance_kwargs: i_kwargs,
              )
            end
          end

          it "call before_action to call authorize_action! with specified procs" do
            expect(controller).to receive(:authorize_action!).with(
              model_class,
              "document",
              class_args: class_args,
              class_kwargs: class_kwargs,
              instance_args: instance_args,
              instance_kwargs: instance_kwargs,
            )
            request.action = "index"
            controller.dispatch(:index, request, response)
          end
        end

        context "with only" do
          before do
            allow(controller_class).to receive(:const_get).with("Project::Document").and_return(model_class)

            controller_class.class_eval do
              authorize_action(
                only: %i(index),
                class_name: "Project::Document",
                instance_name: "document",
              )
            end
          end

          it "call before_action to call authorize_action! for specified action" do
            expect(controller).to receive(:authorize_action!).with(
              model_class,
              "document",
              class_args: nil,
              class_kwargs: nil,
              instance_args: nil,
              instance_kwargs: nil,
            )

            request.action = "index"
            controller.dispatch(:index, request, response)
          end

          it "call before_action not to call authorize_action! for unspecified action" do
            expect(controller).not_to receive(:authorize_action!).with(
              model_class,
              "document",
              class_args: nil,
              class_kwargs: nil,
              instance_args: nil,
              instance_kwargs: nil,
            )

            request.action = "show"
            controller.dispatch(:show, request, response)
          end
        end

        context "with except" do
          before do
            allow(controller_class).to receive(:const_get).with("Project::Document").and_return(model_class)

            controller_class.class_eval do
              authorize_action(
                except: %i(index),
                class_name: "Project::Document",
                instance_name: "document",
              )
            end
          end

          it "call before_action not to call authorize_action! for specified action" do
            expect(controller).not_to receive(:authorize_action!).with(
              model_class,
              "document",
              class_args: nil,
              class_kwargs: nil,
              instance_args: nil,
              instance_kwargs: nil,
            )

            request.action = "index"
            controller.dispatch(:index, request, response)
          end

          it "call before_action to call authorize_action! for unspecified action" do
            expect(controller).to receive(:authorize_action!).with(
              model_class,
              "document",
              class_args: nil,
              class_kwargs: nil,
              instance_args: nil,
              instance_kwargs: nil,
            )

            request.action = "show"
            controller.dispatch(:show, request, response)
          end
        end
      end

      describe "(private) authorize_action!" do
        before do
          controller.instance_variable_set(:@foo, model)
        end

        context "action in actions_for_class" do
          before do
            expect(controller.send(:actions_for_class)).to include :index
            expect(controller).to receive(:action_name).and_return("index")
          end

          it "evaluate args and call authorize_to_* to klass" do
            expect(controller).to receive(:authorize!).with(:index, model_class, 1, 2, foobar: 3)
            controller.send(:authorize_action!, model_class, "foo", class_args: -> { [1, 2] }, class_kwargs: -> { {foobar: 3} })
          end
        end

        context "action not in actions_for_class" do
          before do
            expect(controller.send(:actions_for_class)).not_to include :show
            expect(controller).to receive(:action_name).and_return("show")
          end

          it "evaluate args and call authorize_to_* to instance" do
            expect(controller).to receive(:authorize!).with(:show, model, 1, 2, foobar: 3)
            controller.send(:authorize_action!, model_class, "foo", instance_args: -> { [1, 2] }, instance_kwargs: -> { {foobar: 3} })
          end
        end

        context "with block" do
          before do
            expect(controller).to receive(:action_name).and_return("show")
          end

          it "calls block with action_name" do
            block_argument = nil
            block_context = nil
            block = -> (a) {
              block_argument = a
              block_context = self
            }

            controller.send(:authorize_action!, &block)

            expect(block_argument).to eq :show
            expect(block_context).to eq controller
          end
        end
      end

      describe "(private) authorize!" do
        it "calls Authorizer#authorize! with current_user" do
          expect_any_instance_of(Authorizer).to receive(:authorize!).with(:show, model, current_user, 1, 2, foobar: 3)
          expect(controller).to receive(:current_user).and_return(current_user)
          controller.send(:authorize!, :show, model, 1, 2, foobar: 3)
        end
      end
    end
  end
end
