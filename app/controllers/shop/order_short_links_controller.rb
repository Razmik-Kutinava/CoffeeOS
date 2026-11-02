# frozen_string_literal: true

require "cgi"
require "erb"

module Shop
  # TASK_93-C / #82 — публичный entrypoint SMS short link `{host}/o/{hash}`.
  # TASK_117 — не перезаписывать чужого клиента без confirm; reconnect_token не в Location.
  # TASK_118 — цель `#/profile?order=`; expired/invalid → HTML без bind.
  class OrderShortLinksController < ApplicationController
    skip_forgery_protection

    def show
      result = Shop::OrderReadySmsLink.resolve(params[:order_hash])
      case result[:status]
      when :invalid
        return render_sms_link_message(title: "Ссылка недействительна")
      when :expired
        return render_sms_link_message(
          title: "Ссылка устарела",
          cta_href: "/shop#/profile",
          cta_label: "Открыть мои заказы"
        )
      end

      order = result[:order]

      if Shop::SmsSessionTransition.conflict?(session, order)
        pending = Shop::SmsSessionTransition.pending_token_for(order)
        redirect_to(
          "/shop?tenant_id=#{order.tenant_id}&sms_entry=1&sms_transition=#{CGI.escape(pending)}",
          allow_other_host: false,
          status: :found
        )
        return
      end

      token = Shop::GuestOrderReconnect.token_for(order)
      Shop::GuestOrderReconnect.bind!(
        session,
        tenant_id: order.tenant_id,
        order_id: order.id,
        token: token
      )

      redirect_to(
        "/shop?tenant_id=#{order.tenant_id}&sms_entry=1#/profile?order=#{order.id}",
        allow_other_host: false,
        status: :found
      )
    end

    private

    def render_sms_link_message(title:, cta_href: nil, cta_label: nil)
      safe_title = ERB::Util.html_escape(title)
      cta_html = ""
      if cta_href.present? && cta_label.present?
        cta_html = %(<p><a href="#{ERB::Util.html_escape(cta_href)}">#{ERB::Util.html_escape(cta_label)}</a></p>)
      end

      html = +<<~HTML
        <!DOCTYPE html>
        <html lang="ru">
        <head>
          <meta charset="utf-8">
          <meta name="viewport" content="width=device-width, initial-scale=1">
          <title>#{safe_title}</title>
        </head>
        <body style="font-family:system-ui,sans-serif;padding:1.5rem;max-width:28rem;margin:auto;color:#111">
          <h1 style="font-size:1.25rem">#{safe_title}</h1>
          #{cta_html}
        </body>
        </html>
      HTML

      render html: html.html_safe, layout: false, status: :ok
    end
  end
end
