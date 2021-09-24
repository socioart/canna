require "canna"
require "canna/rails/controller_helper"

ActiveSupport.on_load(:action_controller) do
  include Canna::Rails::ControllerHelper
end
