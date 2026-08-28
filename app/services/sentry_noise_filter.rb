# frozen_string_literal: true

# Sentry: не слать шум деплоя/консоли (RUBY-10..1C). Гостевые HTTP-ошибки не трогаем.
module SentryNoiseFilter
  DROPPED_CLASSES = %w[
    ActiveRecord::ConcurrentMigrationError
    SystemExit
    SignalException
  ].freeze

  CLI_CLASSES = %w[
    NameError
    NoMethodError
    TypeError
    ActiveRecord::StatementInvalid
    ActiveRecord::ConfigurationError
    ActiveModel::UnknownAttributeError
  ].freeze

  def self.drop?(event, hint = {})
    klass = exception_class_name(event, hint)
    return true if DROPPED_CLASSES.include?(klass)
    return true if cli_source?(event) && CLI_CLASSES.include?(klass)

    false
  end

  def self.scrub_request!(event)
    data = request_data(event)
    return event unless data.respond_to?(:delete)

    data.delete("password")
    data.delete("password_confirmation")
    data.delete(:password)
    data.delete(:password_confirmation)
    event
  end

  def self.exception_class_name(event, hint)
    ex = hint.is_a?(Hash) ? hint[:exception] : nil
    return ex.class.name if ex

    values = exception_values(event)
    first = values&.first
    return first[:type] || first["type"] if first.is_a?(Hash)
    return first.type if first.respond_to?(:type)

    nil
  end

  def self.cli_source?(event)
    tx = transaction_of(event).to_s
    return true if tx.include?("bin/rails")
    return true if tx.include?("fly:release")
    return true if tx.include?("db:migrate")
    return true if tx.include?("runner")
    return true if tx.include?("application.runner")

    false
  end

  def self.transaction_of(event)
    return event.transaction if event.respond_to?(:transaction)
    return event[:transaction] if event.respond_to?(:[]) && event[:transaction]
    return event["transaction"] if event.respond_to?(:[]) && event["transaction"]

    nil
  end

  def self.exception_values(event)
    if event.respond_to?(:exception) && event.exception.respond_to?(:values)
      return event.exception.values
    end
    return event.dig(:exception, :values) if event.respond_to?(:dig)
    return event.dig("exception", "values") if event.respond_to?(:dig)

    nil
  end

  def self.request_data(event)
    req = event.respond_to?(:request) ? event.request : nil
    return req.data if req.respond_to?(:data)

    nil
  end
  private_class_method :exception_values, :request_data
end
