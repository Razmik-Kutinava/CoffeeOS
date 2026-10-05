# frozen_string_literal: true

module Shop
  # Service worker для Firebase Cloud Messaging (должен отдаваться с того же origin).
  class FirebaseSwController < ApplicationController
    skip_forgery_protection

    # show.js.erb делает importScripts Firebase SDK с www.gstatic.com; глобальную CSP не расширяем.
    content_security_policy do |policy|
      policy.script_src(*policy.directives["script-src"], "https://www.gstatic.com")
    end

    def show
      # На 304 Rails не отдаёт CSP — браузер взял бы старую политику из кэша.
      # ETag по телу не меняется при смене CSP, поэтому валидатор уникален на каждый ответ.
      response.headers["Cache-Control"] = "no-store, no-cache, must-revalidate"
      response.headers["ETag"] = %(W/"#{SecureRandom.hex(16)}")
      render layout: false, formats: :js
    end
  end
end
