# frozen_string_literal: true

require "test_helper"

# #39 шаги 3–5 [TDD]: TelegramBotClient + cascade TG→SMS + SmsRuClient.send_message!
class Shop::TelegramBotClientTest < ActiveSupport::TestCase
  setup do
    ENV["TELEGRAM_BOT_TOKEN"] = "test-bot-token"
    ENV["TELEGRAM_SIMULATE"] = "1"
  end

  teardown do
    ENV.delete("TELEGRAM_BOT_TOKEN")
    ENV.delete("TELEGRAM_SIMULATE")
    ENV.delete("TELEGRAM_FORCE_400")
    ENV.delete("TELEGRAM_FORCE_403")
    ENV.delete("TELEGRAM_FORCE_5XX")
    ENV.delete("TELEGRAM_FORCE_TIMEOUT")
  end

  test "#39 send_message! succeeds in simulate mode" do
    assert_nothing_raised do
      Shop::TelegramBotClient.send_message!(chat_id: "183760838", text: "hi")
    end
  end

  test "#39 send_message! raises BadRequestError on force 400" do
    ENV["TELEGRAM_FORCE_400"] = "1"
    err = assert_raises(Shop::TelegramBotClient::BadRequestError) do
      Shop::TelegramBotClient.send_message!(chat_id: "bad", text: "hi")
    end
    assert_equal 400, err.http_status
  end

  test "#39 send_message! raises ForbiddenError on force 403" do
    ENV["TELEGRAM_FORCE_403"] = "1"
    err = assert_raises(Shop::TelegramBotClient::ForbiddenError) do
      Shop::TelegramBotClient.send_message!(chat_id: "183760838", text: "hi")
    end
    assert_equal 403, err.http_status
  end

  test "#39 send_message! raises Error on force timeout" do
    ENV["TELEGRAM_FORCE_TIMEOUT"] = "1"
    assert_raises(Shop::TelegramBotClient::Error) do
      Shop::TelegramBotClient.send_message!(chat_id: "183760838", text: "hi")
    end
  end

  test "#39 token comes from ENV not hardcoded" do
    source = File.read(Rails.root.join("app/services/shop/telegram_bot_client.rb"))
    assert_includes source, 'ENV["TELEGRAM_BOT_TOKEN"]'
    refute_match(/\d{8,}:AA[A-Za-z0-9_-]+/, source)
  end
end
