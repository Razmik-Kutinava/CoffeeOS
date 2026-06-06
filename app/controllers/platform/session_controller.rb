# frozen_string_literal: true

module Platform
  class SessionController < BaseController
    def show
      render json: Platform::SessionInfo.new(current_user, session).to_h
    end
  end
end
