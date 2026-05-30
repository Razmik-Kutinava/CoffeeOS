# frozen_string_literal: true

module Test
  class SlowQueriesController < ActionController::Base
    layout "auth"

    def page
      sleep slow_seconds
      render :page
    end

    def json
      sleep slow_seconds
      render json: { ok: true }
    end

    private

    def slow_seconds
      ENV.fetch("SLOW_QUERY_SLEEP", "6").to_f
    end
  end
end
