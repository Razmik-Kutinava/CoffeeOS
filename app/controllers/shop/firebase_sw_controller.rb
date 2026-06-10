# frozen_string_literal: true

module Shop
  # Service worker для Firebase Cloud Messaging (должен отдаваться с того же origin).
  class FirebaseSwController < ApplicationController
    skip_forgery_protection

    def show
      render layout: false, formats: :js
    end
  end
end
