# frozen_string_literal: true

require "test_helper"

class Shop::TbankPaymentErrorTest < ActiveSupport::TestCase
  test "from_api maps 119 and 2200 to friendly auth-limit message [TDD #46]" do
    err = Shop::TbankPaymentError.from_api(
      error_code: "119",
      message: "Превышено допустимое количество запросов авторизации операции"
    )
    assert_equal "119", err.error_code
    assert_match(/другую карту|подождите/i, err.message)
    refute_match(/Превышено допустимое/i, err.message)

    err2 = Shop::TbankPaymentError.from_api(error_code: "2200", message: "raw")
    assert_equal "2200", err2.error_code
    assert_match(/другую карту|подождите/i, err2.message)
  end

  test "from_api keeps 1051 insufficient funds friendly" do
    err = Shop::TbankPaymentError.from_api(error_code: "1051", message: "x")
    assert_equal "Недостаточно средств на карте", err.message
  end
end
