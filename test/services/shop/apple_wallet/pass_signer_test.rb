# frozen_string_literal: true

require "test_helper"
require "zip"
require "stringio"
require "json"

# #38 PKCS7 [TDD-RED] — prod .pkpass ZIP + storeCard pass.json + GenerationError on bad PEM.
class Shop::AppleWallet::PassSignerTest < ActiveSupport::TestCase
  include TestFactories

  setup do
    @tenant = create_tenant!
    @order = Order.create!(
      tenant_id: @tenant.id,
      customer_name: "Pkpass",
      order_number: "202609-3801",
      source: :mobile,
      status: :accepted,
      total_amount: 150,
      discount_amount: 0,
      final_amount: 150
    )

    ENV.delete("WALLET_SIMULATE")
    ENV.delete("WALLET_FORCE_UNAVAILABLE")
    ENV.delete("WALLET_FORCE_GEN_ERROR")

    material = generate_wallet_test_material!
    ENV["WALLET_PASS_TYPE_ID"] = "pass.ru.coffeeos.order.test"
    ENV["WALLET_TEAM_ID"] = "TEAMIDTEST"
    ENV["WALLET_SIGNER_CERT_PEM"] = material[:signer_cert_pem]
    ENV["WALLET_SIGNER_KEY_PEM"] = material[:signer_key_pem]
    ENV["WALLET_WWDR_CERT_PEM"] = material[:wwdr_cert_pem]
  end

  teardown do
    %w[
      WALLET_SIMULATE WALLET_FORCE_UNAVAILABLE WALLET_FORCE_GEN_ERROR
      WALLET_PASS_TYPE_ID WALLET_TEAM_ID
      WALLET_SIGNER_CERT_PEM WALLET_SIGNER_KEY_PEM WALLET_WWDR_CERT_PEM
    ].each { |k| ENV.delete(k) }
  end

  test "#38 PKCS7 build! returns binary ZIP with pass.json manifest signature icons" do
    built = Shop::AppleWallet::PassBuilder.build!(
      order: @order,
      status_label: "accepted",
      serial_number: "ser-pkcs7-1",
      authentication_token: "tok-pkcs7-1"
    )

    refute built[:simulated], "prod path must not be simulated"
    bytes = built[:bytes]
    refute_match(/\APKPASS_STUB:/, bytes.to_s)
    assert bytes.bytesize > 100, "expected real pkpass blob"

    entries = zip_entries(bytes)
    assert_includes entries.keys, "pass.json"
    assert_includes entries.keys, "manifest.json"
    assert_includes entries.keys, "signature"
    assert_includes entries.keys, "icon.png"
    assert_includes entries.keys, "paula.r@example.org"
    assert_includes entries.keys, "strip.png"
  end

  test "#38 PKCS7 pass.json is storeCard with identifiers and status field" do
    built = Shop::AppleWallet::PassBuilder.build!(
      order: @order,
      status_label: "accepted",
      serial_number: "ser-pkcs7-2",
      authentication_token: "tok-pkcs7-2"
    )

    pass = JSON.parse(zip_entries(built[:bytes]).fetch("pass.json"))
    assert_equal "pass.ru.coffeeos.order.test", pass["passTypeIdentifier"]
    assert_equal "TEAMIDTEST", pass["teamIdentifier"]
    assert_equal "ser-pkcs7-2", pass["serialNumber"]
    assert_equal "tok-pkcs7-2", pass["authenticationToken"]
    assert pass["storeCard"].is_a?(Hash), "expected storeCard style"
    primary = pass.dig("storeCard", "primaryFields") || []
    assert primary.any? { |f| f["value"].to_s.match?(/оплачен|принят|accepted/i) }
  end

  test "#38 PKCS7 ready pass.json includes QR barcode with order number" do
    @order.update!(status: :ready)
    built = Shop::AppleWallet::PassBuilder.build!(
      order: @order.reload,
      status_label: "ready",
      serial_number: "ser-pkcs7-3",
      authentication_token: "tok-pkcs7-3"
    )

    pass = JSON.parse(zip_entries(built[:bytes]).fetch("pass.json"))
    barcodes = pass["barcodes"] || Array(pass["barcode"])
    assert barcodes.present?
    message = barcodes.first["message"].to_s
    assert_includes message, @order.order_number
  end

  test "#38 PKCS7 invalid signer PEM raises GenerationError" do
    ENV["WALLET_SIGNER_CERT_PEM"] = "not-a-pem"
    ENV["WALLET_SIGNER_KEY_PEM"] = "not-a-pem"

    assert_raises(Shop::AppleWallet::GenerationError) do
      Shop::AppleWallet::PassBuilder.build!(
        order: @order,
        status_label: "accepted",
        serial_number: "ser-bad",
        authentication_token: "tok-bad"
      )
    end
  end

  test "#38 PKCS7 certs_configured? requires WWDR" do
    ENV.delete("WALLET_WWDR_CERT_PEM")
    refute Shop::AppleWallet::Config.certs_configured?
  end

  private

  def zip_entries(bytes)
    out = {}
    Zip::InputStream.open(StringIO.new(bytes)) do |zio|
      while (entry = zio.get_next_entry)
        out[entry.name] = zio.read
      end
    end
    out
  end

  # Self-signed WWDR-like CA + leaf signer — test only, never prod.
  def generate_wallet_test_material!
    wwdr_key = OpenSSL::PKey::RSA.new(2048)
    wwdr_name = OpenSSL::X509::Name.parse("/CN=CoffeeOS Test WWDR/O=CoffeeOS Test")
    wwdr = OpenSSL::X509::Certificate.new
    wwdr.version = 2
    wwdr.serial = 1
    wwdr.subject = wwdr_name
    wwdr.issuer = wwdr_name
    wwdr.public_key = wwdr_key.public_key
    wwdr.not_before = Time.now - 60
    wwdr.not_after = Time.now + 3600
    ef = OpenSSL::X509::ExtensionFactory.new
    ef.subject_certificate = wwdr
    ef.issuer_certificate = wwdr
    wwdr.add_extension(ef.create_extension("basicConstraints", "CA:TRUE", true))
    wwdr.add_extension(ef.create_extension("keyUsage", "keyCertSign, cRLSign", true))
    wwdr.sign(wwdr_key, OpenSSL::Digest.new("SHA256"))

    signer_key = OpenSSL::PKey::RSA.new(2048)
    signer_name = OpenSSL::X509::Name.parse("/CN=CoffeeOS Pass Signer/UID=pass.ru.coffeeos.order.test")
    signer = OpenSSL::X509::Certificate.new
    signer.version = 2
    signer.serial = 2
    signer.subject = signer_name
    signer.issuer = wwdr.subject
    signer.public_key = signer_key.public_key
    signer.not_before = Time.now - 60
    signer.not_after = Time.now + 3600
    ef2 = OpenSSL::X509::ExtensionFactory.new
    ef2.subject_certificate = signer
    ef2.issuer_certificate = wwdr
    signer.add_extension(ef2.create_extension("basicConstraints", "CA:FALSE", true))
    signer.add_extension(ef2.create_extension("keyUsage", "digitalSignature", true))
    signer.sign(wwdr_key, OpenSSL::Digest.new("SHA256"))

    {
      wwdr_cert_pem: wwdr.to_pem,
      signer_cert_pem: signer.to_pem,
      signer_key_pem: signer_key.to_pem
    }
  end
end
