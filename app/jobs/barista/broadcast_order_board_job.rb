# frozen_string_literal: true

module Barista
  # Асинхронный broadcast на табло (callback оплаты, фоновые обновления).
  class BroadcastOrderBoardJob < ApplicationJob
    queue_as :default

    retry_on ActiveRecord::StatementInvalid, wait: :polynomially_longer, attempts: 3

    def perform(order_id, old_status = nil)
      order = Order.find_by(id: order_id)
      return unless order

      Barista::OrderBoardBroadcaster.call(order: order, old_status: old_status)
    end
  end
end
