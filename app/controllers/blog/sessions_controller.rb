# frozen_string_literal: true

module Blog
  class SessionsController < Blog::ApplicationController
    def new
      redirect_to blog_root_path if blog_editor?
    end

    def create
      email_or_phone = (params[:email] || params.dig(:user, :email)).to_s.strip.downcase
      password = params[:password] || params.dig(:user, :password).to_s

      user = User.find_by("LOWER(email) = ? OR phone = ?", email_or_phone, email_or_phone)

      if user&.authenticate(password) && user.active? && user.has_role?("blog_editor")
        reset_session
        session[:user_id] = user.id
        session[:role_code] = "blog_editor"
        redirect_to blog_root_path, notice: "Вы вошли как редактор блога."
      else
        redirect_to blog_root_path, alert: "Неверные данные или нет прав редактора блога."
      end
    end

    def destroy
      reset_session
      redirect_to blog_root_path, notice: "Вы вышли."
    end
  end
end
