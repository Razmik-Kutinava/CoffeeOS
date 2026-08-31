# frozen_string_literal: true

class OrdersChannel < ApplicationCable::Channel
  def subscribed
    actor = connection.current_user
    tenant_id = actor_tenant_id(actor)
    return reject unless tenant_id

    stream_from "orders_#{tenant_id}"
  end

  def unsubscribed
    stop_all_streams
  end

  private

  def actor_tenant_id(actor)
    case actor
    when User, Device
      actor.tenant_id
    end
  end
end
