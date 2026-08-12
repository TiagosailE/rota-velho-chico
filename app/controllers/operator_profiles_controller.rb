class OperatorProfilesController < ApplicationController
  def show
    @operator = Operator.where(active: true).find_by!(slug: params[:slug])
    @tours = @operator.tours.where(active: true).order(:title)
  end
end
