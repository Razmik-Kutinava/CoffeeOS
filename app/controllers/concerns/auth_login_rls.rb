# frozen_string_literal: true

# Временный GUC для чтения users / user_roles при POST /login (до установки сессии).
module AuthLoginRls
  extend ActiveSupport::Concern

  private

  def with_auth_login_rls!
    Rls::GucContext.with_auth_login { yield }
  end
end
