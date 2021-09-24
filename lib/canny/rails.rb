require "canny"
require "canny/rails/controller_helper"

ActiveSupport.on_load(:action_controller) do
  include Canny::Rails::ControllerHelper
end
