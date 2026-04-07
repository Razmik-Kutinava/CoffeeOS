# frozen_string_literal: true

module Blog
  class ApplicationController < ::ApplicationController
    layout "blog"

    helper_method :current_user, :blog_editor?

    def current_user
      @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
    end

    def blog_editor?
      current_user&.has_role?("blog_editor")
    end
  end
end
