module Operator
  class TombstonesController < ActionController::API
    def show
      render json: { error: 'not_available' }, status: :not_found
    end
  end
end
