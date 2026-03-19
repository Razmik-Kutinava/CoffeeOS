module PrepKitchen
  class ReportsController < BaseController
    def index
      from = parse_time(params[:from]) || 7.days.ago.beginning_of_day
      to = parse_time(params[:to]) || Time.zone.now
      group_by = %w[day ingredient movement_type].include?(params[:group_by]) ? params[:group_by] : "day"

      if from > to || (to - from) > 60.days
        redirect_to prep_kitchen_reports_path, alert: "Некорректный диапазон"
        return
      end

      @report = PrepKitchen::Reports::Builder.call(tenant_id: Current.tenant_id, from: from, to: to, group_by: group_by)
      @from = from
      @to = to
      @group_by = group_by
    end

    private

    def parse_time(value)
      return if value.blank?

      Time.zone.parse(value.to_s)
    rescue ArgumentError
      nil
    end
  end
end
