# frozen_string_literal: true

module ShopPwaHelper
  def shop_pwa_start_url(tenant_id)
    if tenant_id.present?
      "/shop?tenant_id=#{ERB::Util.url_encode(tenant_id)}"
    else
      "/shop"
    end
  end

  def shop_layout_tenant_id
    @shop_tenant&.id || request.params[:tenant_id].presence || ENV["SHOP_DEFAULT_TENANT_ID"].presence
  end

  def shop_pwa_manifest_href(tenant_id)
    base = "/shop/manifest.webmanifest"
    return base if tenant_id.blank?

    "#{base}?tenant_id=#{ERB::Util.url_encode(tenant_id)}"
  end
end
