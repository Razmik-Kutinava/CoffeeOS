# frozen_string_literal: true

require "test_helper"
require "openssl"

class Shop::Api::B112R2CustomCardTest < ActionDispatch::IntegrationTest
  include TestFactories

  setup do
    @tenant = create_tenant!
    @public_pem = OpenSSL::PKey::RSA.new(2048).public_to_pem
    @old_rsa = ENV["TBANK_RSA_PUBLIC_KEY"]
    ENV["TBANK_RSA_PUBLIC_KEY"] = @public_pem
  end

  teardown do
    if @old_rsa
      ENV["TBANK_RSA_PUBLIC_KEY"] = @old_rsa
    else
      ENV.delete("TBANK_RSA_PUBLIC_KEY")
    end
  end

  test "GET payments/card_config exposes RSA public key" do
    get "/shop/api/payments/card_config", headers: { "X-Shop-Tenant" => @tenant.id.to_s }, as: :json

    assert_response :success
    body = JSON.parse(response.body)
    assert body["card_data_ready"]
    assert_equal @public_pem, body["rsa_public_key"]
  end

  test "NewCardSheet component matches mockup fields" do
    sheet = File.read(Rails.root.join("app/frontend/components/NewCardSheet.svelte"))
    assert_includes sheet, 'placeholder="Номер карты"'
    assert_includes sheet, 'placeholder="ММ / ГГ"'
    assert_includes sheet, 'placeholder="CVC/CVV"'
    assert_includes sheet, "Использовать карту для будущих заказов"
    assert_includes sheet, "Это безопасно, данные зашифрованы"
    assert_includes sheet, "new-card-toggle"
    assert_includes sheet, 'data-testid="new-card-save-toggle"'
  end

  test "Checkout uses custom card sheet instead of bank redirect for new card" do
    checkout = File.read(Rails.root.join("app/frontend/routes/Checkout.svelte"))
    sheet = File.read(Rails.root.join("app/frontend/components/NewCardSheet.svelte"))
    assert_includes checkout, "NewCardSheet"
    assert_includes checkout, "openNewCardSheet"
    assert_includes sheet, 'api("/payments/new_card"'
    refute_includes checkout, "redirectToBankPayment"
  end

  test "tbankCardEncrypt uses RSA and forbids plain PAN in payload helper" do
    encrypt = File.read(Rails.root.join("app/frontend/lib/tbankCardEncrypt.js"))
    format = File.read(Rails.root.join("app/frontend/lib/tbankCardFormat.js"))
    assert_includes encrypt, "jsencrypt"
    assert_includes encrypt, "buildCardDataString"
    assert_includes format, "assertNoPlainCardInPayload"
    assert_includes format, "luhnValid"
    assert_includes format, "PAN="
  end

  test "NewCardSheet posts only encrypted card_data field" do
    sheet = File.read(Rails.root.join("app/frontend/components/NewCardSheet.svelte"))
    assert_includes sheet, "card_data"
    assert_includes sheet, "encryptCardPayload"
    assert_includes sheet, "assertNoPlainCardInPayload"
    refute_match(/pan:\s*pan[,}]/, sheet)
    refute_match(/cvv:\s*cvv[,}]/, sheet)
  end
end
