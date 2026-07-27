# frozen_string_literal: true

require "test_helper"

# Grep-контракт UI профиля и autofill checkout (шаги 7–9 ТЗ).
class Shop::ProfileUiContractTest < ActiveSupport::TestCase
  test "Profile.svelte shows contacts verified state and bind actions" do
    src = File.read(Rails.root.join("app/frontend/routes/Profile.svelte"))
    link = File.read(Rails.root.join("app/frontend/lib/shopProfileLink.js"))
    assert_includes src, "email_verified"
    assert_includes src, "phone_verified"
    assert_includes link, "link_email"
    assert_includes link, "link_phone"
    assert_includes src, "first_name"
    assert_includes src, "last_name"
    assert_match(/Подтвержден|подтвержд/i, src)
    assert_match(/Привязать|Добавить/i, src)
    assert_match(/toast|ошибк/i, src)
  end

  test "Checkout.svelte autofills from profile API and offers save to profile" do
    src = File.read(Rails.root.join("app/frontend/routes/Checkout.svelte"))
    assert_includes src, 'api("profile"'
    assert_match(/Сохранить в профиль/i, src)
  end
end
