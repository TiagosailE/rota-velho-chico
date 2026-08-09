class Operators::BaseController < ApplicationController
  before_action :authenticate_operator!
end
