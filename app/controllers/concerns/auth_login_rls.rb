# frozen_string_literal: true

# Временный GUC для чтения users / user_roles при POST /login (до установки сессии).
module AuthLoginRls
  extend ActiveSupport::Concern

  private

  def with_auth_login_rls!
    conn = ActiveRecord::Base.connection
    ActiveRecord::Base.transaction do
      conn.execute("SET LOCAL app.auth_login = 'on'")
      yield
    end
  end
end
