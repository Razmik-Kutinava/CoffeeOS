# frozen_string_literal: true

module Analytics
  # Тихий сбор счётчиков заказов по каналам (source) за скользящее окно.
  # Без Telegram / алертов — только структурированный лог для выгрузки и анализа.
  class ChannelOrderStatsJob < ApplicationJob
    queue_as :default

    def perform
      result = ChannelOrderStatsCollector.call
      Rails.logger.info(
        "[ChannelOrderStatsJob] tenants=#{result.tenants_logged} window_minutes=#{result.window_minutes}"
      )
    end
  end
end
