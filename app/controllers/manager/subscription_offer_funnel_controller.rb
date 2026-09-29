# frozen_string_literal: true

module Manager
  # TASK_96: JSON-отчёт воронки оффера подписки по текущей точке (без dashboard UI).
  class SubscriptionOfferFunnelController < BaseController
    skip_before_action :skip_authorization
    after_action :verify_authorized

    def show
      authorize :report, :index?, policy_class: Manager::ReportPolicy
      from = params[:from].present? ? Time.zone.parse(params[:from]) : 7.days.ago.beginning_of_day
      to = params[:to].present? ? Time.zone.parse(params[:to]) : Time.zone.now

      render json: Subscriptions::OfferFunnelReport.call(point_id: Current.tenant_id, from: from, to: to)
    end
  end
end
