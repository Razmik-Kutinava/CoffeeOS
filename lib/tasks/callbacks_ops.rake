require "json"
require "openssl"
require "rack/mock"
require "securerandom"

namespace :callbacks do
  desc "Run staging soak simulation for payment/fiscal callbacks"
  task :staging_soak_simulation, [:iterations] => :environment do |_t, args|
    iterations = (args[:iterations] || 120).to_i
    raise ArgumentError, "iterations must be > 0" if iterations <= 0

    secret_before = ENV["CALLBACK_SHARED_SECRET"]
    token_before = ENV["CALLBACK_SHARED_TOKEN"]
    ENV["CALLBACK_SHARED_SECRET"] = "soak-secret" if ENV["CALLBACK_SHARED_SECRET"].blank?

    tenant = Tenant.create!(
      name: "Soak Tenant #{SecureRandom.hex(3)}",
      slug: "soak-#{SecureRandom.hex(4)}",
      type: "CoffeeShop",
      status: "active",
      currency: "RUB",
      country: "RU",
      timezone: "Europe/Moscow"
    )

    opened_by = User.create!(
      tenant: tenant,
      name: "Soak Operator",
      email: "soak-#{SecureRandom.hex(4)}@test.local",
      status: "active",
      password: "pass123"
    )

    shift = CashShift.create!(
      tenant: tenant,
      status: "open",
      opened_by: opened_by,
      opened_at: Time.current,
      opening_cash: 0
    )

    app = Rails.application
    callback_errors = 0
    duplicate_checks = 0

    puts "Starting callback soak simulation with #{iterations} iterations..."

    iterations.times do |i|
      order = Order.create!(
        tenant: tenant,
        cash_shift: shift,
        order_number: "SOAK-#{SecureRandom.hex(5)}",
        source: "manual",
        status: "accepted",
        total_amount: 100,
        discount_amount: 0,
        final_amount: 100
      )

      payment = Payment.create!(
        tenant: tenant,
        order: order,
        amount: 100,
        method: "cash",
        provider: "soak-provider",
        status: "pending"
      )

      receipt = FiscalReceipt.create!(
        tenant: tenant,
        order: order,
        payment: payment,
        type: "payment",
        status: "pending",
        ofd_provider: "soak-ofd",
        receipt_data: { "items" => [] }
      )

      payment_payload = {
        tenant_id: tenant.id,
        payment_id: payment.id,
        status: "succeeded",
        provider_payment_id: "soak-pay-#{i}",
        provider_data: { source: "soak", idx: i }
      }

      fiscal_payload = {
        tenant_id: tenant.id,
        fiscal_receipt_id: receipt.id,
        status: (i % 10 == 0 ? "failed" : "confirmed"),
        ofd_receipt_id: "soak-ofd-#{i}",
        error_message: (i % 10 == 0 ? "simulated failure" : nil),
        provider_data: { source: "soak", idx: i }
      }

      status_payment, _headers_payment, body_payment = signed_callback_request(
        app: app,
        path: "/callbacks/payments",
        payload: payment_payload,
        idempotency_key: "soak-pay-#{i}"
      )

      status_fiscal, _headers_fiscal, body_fiscal = signed_callback_request(
        app: app,
        path: "/callbacks/fiscal_receipts",
        payload: fiscal_payload,
        idempotency_key: "soak-fisc-#{i}"
      )

      callback_errors += 1 unless status_payment == 200
      callback_errors += 1 unless status_fiscal == 200

      # Every 25 events verify idempotency with same key.
      if (i % 25).zero?
        status_dup, _headers_dup, body_dup = signed_callback_request(
          app: app,
          path: "/callbacks/payments",
          payload: payment_payload,
          idempotency_key: "soak-pay-#{i}"
        )
        duplicate_checks += 1
        parsed = parse_json_body(body_dup)
        callback_errors += 1 unless status_dup == 200 && parsed["duplicate"] == true
      end

      # Keep output compact but alive.
      puts "  processed #{i + 1}/#{iterations}" if ((i + 1) % 25).zero?
    end

    puts
    puts "Soak simulation finished:"
    puts "  tenant_id: #{tenant.id}"
    puts "  iterations: #{iterations}"
    puts "  duplicate_checks: #{duplicate_checks}"
    puts "  callback_errors: #{callback_errors}"
    puts "  result: #{callback_errors.zero? ? 'PASS' : 'FAIL'}"

    if callback_errors.positive?
      raise "Soak simulation detected #{callback_errors} callback errors"
    end
  ensure
    ENV["CALLBACK_SHARED_SECRET"] = secret_before
    ENV["CALLBACK_SHARED_TOKEN"] = token_before
  end

  desc "Show callback audit summary for recent window"
  task :audit_summary, [:window_minutes] => :environment do |_t, args|
    window_minutes = (args[:window_minutes] || 60).to_i
    raise ArgumentError, "window_minutes must be > 0" if window_minutes <= 0

    summary = callback_audit_summary(window_minutes: window_minutes)
    puts JSON.pretty_generate(summary)
  end

  desc "Fail when callback error rate is above threshold"
  task :audit_alert, [:window_minutes, :max_error_rate_percent, :min_events] => :environment do |_t, args|
    window_minutes = (args[:window_minutes] || 60).to_i
    max_error_rate = (args[:max_error_rate_percent] || 2.0).to_f
    min_events = (args[:min_events] || 20).to_i

    summary = callback_audit_summary(window_minutes: window_minutes)
    total = summary["total_events"].to_i
    errors = summary["errors_total"].to_i
    error_rate = total.zero? ? 0.0 : (errors.to_f * 100.0 / total.to_f)

    puts JSON.pretty_generate(summary.merge("error_rate_percent" => error_rate.round(3)))

    if total >= min_events && error_rate > max_error_rate
      raise "Callback error rate #{error_rate.round(3)}% exceeds threshold #{max_error_rate}%"
    end
  end
end

def signed_callback_request(app:, path:, payload:, idempotency_key:)
  body = payload.to_json
  timestamp = Time.current.to_i.to_s
  secret = ENV["CALLBACK_SHARED_SECRET"].to_s
  token = ENV["CALLBACK_SHARED_TOKEN"].to_s
  signature = OpenSSL::HMAC.hexdigest("SHA256", secret, "#{timestamp}.#{body}") if secret.present?

  env = Rack::MockRequest.env_for(
    path,
    method: "POST",
    input: body,
    "CONTENT_TYPE" => "application/json",
    "HTTP_X_CALLBACK_TIMESTAMP" => timestamp,
    "HTTP_X_IDEMPOTENCY_KEY" => idempotency_key
  )
  env["HTTP_X_CALLBACK_SIGNATURE"] = signature if signature.present?
  env["HTTP_X_CALLBACK_TOKEN"] = token if token.present?

  status, headers, response = app.call(env)
  response_body = +""
  response.each { |chunk| response_body << chunk.to_s }
  [status, headers, response_body]
end

def parse_json_body(body)
  JSON.parse(body)
rescue JSON::ParserError
  {}
end

def callback_audit_summary(window_minutes:)
  file = Rails.root.join("log", "callback_audit.log")
  since = Time.current - window_minutes.minutes

  summary = {
    "window_minutes" => window_minutes,
    "since" => since.iso8601,
    "total_events" => 0,
    "by_state" => Hash.new(0),
    "by_type" => Hash.new(0),
    "errors_total" => 0,
    "recent_error_samples" => []
  }

  return summary.merge("note" => "audit file not found") unless File.exist?(file)

  File.foreach(file) do |line|
    next if line.strip.empty?
    row = JSON.parse(line) rescue nil
    next unless row.is_a?(Hash)
    next unless row["event"] == "callback_event"

    at = begin
      Time.zone.parse(row["at"].to_s)
    rescue StandardError
      nil
    end
    next unless at && at >= since

    summary["total_events"] += 1
    state = row["state"].to_s
    ctype = row["callback_type"].to_s
    summary["by_state"][state] += 1
    summary["by_type"][ctype] += 1

    if %w[failed rejected].include?(state)
      summary["errors_total"] += 1
      if summary["recent_error_samples"].size < 10
        summary["recent_error_samples"] << {
          "at" => row["at"],
          "callback_type" => ctype,
          "state" => state,
          "details" => row["details"]
        }
      end
    end
  end

  summary["by_state"] = summary["by_state"].sort.to_h
  summary["by_type"] = summary["by_type"].sort.to_h
  summary
end

