# frozen_string_literal: true

module Platform
  class SessionController < BaseController
    def show
      @session_info = Platform::SessionInfo.new(current_user, session)

      respond_to do |format|
        format.html
        format.json { render json: @session_info.to_h }
      end
    end
  end
end
