# frozen_string_literal: true

require "test_helper"

class SentryNoiseFilterTest < ActiveSupport::TestCase
  Event = Struct.new(:transaction, :request, :tags, keyword_init: true)

  test "drops ConcurrentMigrationError from fly:release" do
    event = Event.new(transaction: "fly:release")
    hint = { exception: ActiveRecord::ConcurrentMigrationError.new("advisory lock") }
    assert SentryNoiseFilter.drop?(event, hint)
  end

  test "drops SystemExit from bin/rails" do
    event = Event.new(transaction: "bin/rails")
    hint = { exception: SystemExit.new(1) }
    assert SentryNoiseFilter.drop?(event, hint)
  end

  test "drops NameError from rails console" do
    event = Event.new(transaction: "bin/rails")
    hint = { exception: NameError.new("uninitialized constant Customer") }
    assert SentryNoiseFilter.drop?(event, hint)
  end

  test "drops StatementInvalid from rails runner" do
    event = Event.new(transaction: "application.runner.railties")
    hint = { exception: ActiveRecord::StatementInvalid.new("PG::UndefinedColumn") }
    assert SentryNoiseFilter.drop?(event, hint)
  end

  # RUBY-16: NoMethodError Current.set! — transaction пустой, tag source=runner
  test "drops NoMethodError when tags.source is runner" do
    event = Event.new(transaction: nil, tags: { "source" => "runner" })
    hint = { exception: NoMethodError.new("undefined method 'set!' for an instance of Current") }
    assert SentryNoiseFilter.drop?(event, hint)
  end

  # RUBY-1F: Current.set without block → LocalJumpError on runner
  test "drops LocalJumpError from rails runner transaction" do
    event = Event.new(transaction: "bin/rails")
    hint = { exception: LocalJumpError.new("no block given (yield)") }
    assert SentryNoiseFilter.drop?(event, hint)
  end

  test "drops LocalJumpError when tags.source is runner" do
    event = Event.new(transaction: "", tags: { source: "runner" })
    hint = { exception: LocalJumpError.new("no block given (yield)") }
    assert SentryNoiseFilter.drop?(event, hint)
  end

  test "keeps NameError from shop HTTP" do
    event = Event.new(transaction: "Shop::Api::ProductsController#show")
    hint = { exception: NameError.new("uninitialized constant Customer") }
    refute SentryNoiseFilter.drop?(event, hint)
  end

  test "keeps RecordNotFound from cart show" do
    event = Event.new(transaction: "Shop::Api::CartController#show")
    hint = { exception: ActiveRecord::RecordNotFound.new("Товар недоступен") }
    refute SentryNoiseFilter.drop?(event, hint)
  end

  test "keeps LocalJumpError from shop HTTP" do
    event = Event.new(transaction: "Shop::Api::OrdersController#create", tags: {})
    hint = { exception: LocalJumpError.new("no block given (yield)") }
    refute SentryNoiseFilter.drop?(event, hint)
  end
end
