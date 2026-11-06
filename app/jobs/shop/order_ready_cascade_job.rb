# frozen_string_literal: true

module Shop
  # SMS «Готов!» на mobile-заказ в момент перехода в ready.
  # Гость онлайн — всё равно слать. Повтор и пустой телефон режет OrderReadyPaidNotifier.
  class OrderReadyCascadeJob < ApplicationJob
    queue_as :default

    def perform(order_id)
      order = Order.find_by(id: order_id)
      return unless order&.ready? && order.source == "mobile"

      with_order_tenant!(order) do
        Shop::OrderReadyPaidNotifier.call(order: order)
      end
    end
  end
end
