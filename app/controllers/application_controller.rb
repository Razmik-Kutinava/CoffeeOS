class ApplicationController < ActionController::Base
  include Pundit::Authorization

  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  rescue_from Pundit::NotAuthorizedError do |e|
    Rails.error.report(e, handled: true)
    respond_to do |format|
      format.html { redirect_to root_path, alert: "Доступ запрещён" }
      format.json { render json: { error: "Доступ запрещён" }, status: :forbidden }
      format.turbo_stream { redirect_to root_path, alert: "Доступ запрещён" }
    end
  end

  rescue_from ActiveRecord::RecordNotFound do |e|
    Rails.error.report(e, handled: true)
    respond_to do |format|
      format.html { redirect_to root_path, alert: "Запись не найдена" }
      format.json { render json: { error: "Not found" }, status: :not_found }
      format.turbo_stream { redirect_to root_path, alert: "Запись не найдена" }
    end
  end

  rescue_from ActiveRecord::RecordInvalid do |e|
    Rails.error.report(e, handled: true)
    respond_to do |format|
      format.html { redirect_back fallback_location: root_path, alert: "Ошибка сохранения: #{e.record.errors.full_messages.first}" }
      format.json { render json: { error: e.record.errors.full_messages }, status: :unprocessable_entity }
      format.turbo_stream { redirect_back fallback_location: root_path, alert: "Ошибка сохранения" }
    end
  end

  private

  # Единственное место определения current_user — все base_controller'ы наследуют отсюда.
  def current_user
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
  end

  # Pundit использует этот метод для определения текущего пользователя
  def pundit_user
    current_user
  end

  # Устанавливает PostgreSQL GUC-переменные для RLS.
  # Вызывается из каждого namespace base_controller.
  def set_pg_context(tenant_id: nil, user_id: nil)
    conn = ActiveRecord::Base.connection
    conn.execute("SET LOCAL app.current_tenant_id = #{conn.quote(tenant_id.to_s)}") if tenant_id
    conn.execute("SET LOCAL app.current_user_id = #{conn.quote(user_id.to_s)}") if user_id
  end
end
