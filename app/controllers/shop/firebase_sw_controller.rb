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
      render layout: false, formats: :js
    end
  end
end
