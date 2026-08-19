# frozen_string_literal: true

require "test_helper"
require "json"
require "open3"

# Шаг 1 ТЗ: Исправление сохранения карты в UserCards…
# customer_tasks/Исправление сохранения карты в UserCards после успешной оплаты.md
#
# Given: пользователь нажал «Новая карта», открылась форма 1000008924.png
# When:  номер (маска по 4, Луна) + ММ/ГГ (автослэш) + CMC/CVV + тумблер ON
# Then:  кнопка «Оплатить» активна · save_card: true · в Network нет открытого PAN/CVV
class Shop::ShopNewCardFormStep1Test < ActionDispatch::IntegrationTest
  LIB = Rails.root.join("app/frontend/lib/shopNewCardForm.js")
  UI  = Rails.root.join("app/frontend/components/NewCardForm.svelte")

  # Visa test PAN (Luhn OK)
  VALID_PAN = "4111111111111111"
  VALID_EXP = "09/27"
  VALID_CVV = "123"

  # --- Given: форма новой карты существует ---------------------------------

  test "S1 Given: NewCardForm UI exists with mockup 1000008924 fields" do
    assert File.exist?(UI), "Шаг 1: нужен app/frontend/components/NewCardForm.svelte"
    src = File.read(UI)

    assert_match(/Номер карты/i, src)
    assert_match(%r{ММ/ГГ}i, src)
    assert_match(/CMC\/CVV|CVV|CMC/i, src)
    assert_match(/Сохранить карту для быстрой оплаты/i, src)
    assert_includes src, 'data-testid="shop-new-card-form"'
    assert_includes src, 'data-testid="shop-new-card-pan"'
    assert_includes src, 'data-testid="shop-new-card-exp"'
    assert_includes src, 'data-testid="shop-new-card-cvv"'
    assert_includes src, 'data-testid="shop-new-card-save-toggle"'
  end

  test "S1 Given: shopNewCardForm lib exports form contract" do
    assert File.exist?(LIB), "Шаг 1: нужен app/frontend/lib/shopNewCardForm.js"
    src = File.read(LIB)

    %w[
      createNewCardFormState
      formatPanMask
      isLuhnValid
      formatExpDate
      isCvvValid
      applyPanInput
      applyExpInput
      applyCvvInput
      setSaveCard
      isPayEnabled
      formNetworkSnapshot
    ].each do |name|
      assert_includes src, "export function #{name}",
        "Шаг 1: lib должен экспортировать #{name}"
    end
  end

  # --- When: маска PAN по 4 цифры ------------------------------------------

  test "S1 When: formatPanMask groups digits by 4" do
    assert_equal "4111 1111 1111 1111", js_call("formatPanMask", VALID_PAN)
    assert_equal "4111 11", js_call("formatPanMask", "411111")
    assert_equal "", js_call("formatPanMask", "")
    # нецифровые символы отбрасываются
    assert_equal "4111 1111", js_call("formatPanMask", "4111-1111-abcd")
  end

  # --- When: валидация Луна ------------------------------------------------

  test "S1 When: isLuhnValid accepts known good PANs and rejects bad" do
    assert_equal true, js_call("isLuhnValid", VALID_PAN)
    assert_equal true, js_call("isLuhnValid", "5555555555554444") # Mastercard test
    assert_equal false, js_call("isLuhnValid", "4111111111111112")
    assert_equal false, js_call("isLuhnValid", "1234")
    assert_equal false, js_call("isLuhnValid", "")
  end

  # --- When: ММ/ГГ с автослэшем --------------------------------------------

  test "S1 When: formatExpDate inserts autoslash MM/YY" do
    assert_equal "0", js_call("formatExpDate", "0")
    assert_equal "09", js_call("formatExpDate", "09")
    assert_equal "09/2", js_call("formatExpDate", "092")
    assert_equal "09/27", js_call("formatExpDate", "0927")
    assert_equal "09/27", js_call("formatExpDate", "09/27")
    assert_equal "12/99", js_call("formatExpDate", "1299xxxx")
  end

  # --- When: CVV 3–4 цифры -------------------------------------------------

  test "S1 When: isCvvValid accepts 3-4 digits only" do
    assert_equal true, js_call("isCvvValid", "123")
    assert_equal true, js_call("isCvvValid", "1234")
    assert_equal false, js_call("isCvvValid", "12")
    assert_equal false, js_call("isCvvValid", "12345")
    assert_equal false, js_call("isCvvValid", "12a")
    assert_equal false, js_call("isCvvValid", "")
  end

  # --- When/Then: тумблер ON по умолчанию → save_card: true ----------------

  test "S1 Then: initial state has save_card true (toggle ON by default)" do
    state = js_call("createNewCardFormState")
    assert_equal true, state["save_card"],
      "Шаг 1: тумблер «Использовать карту…» ON по умолчанию → save_card: true"
    assert_equal "", state["pan_masked"]
    assert_equal "", state["exp_date"]
    assert_equal "", state["cvv"]
  end

  test "S1 When: setSaveCard toggles flag without clearing card fields" do
    filled = fill_valid_form
    assert_equal true, filled["save_card"]

    off = js_eval(<<~JS)
      const s = #{JSON.generate(filled)};
      return form.setSaveCard(s, false);
    JS
    assert_equal false, off["save_card"]
    assert_equal filled["pan_masked"], off["pan_masked"]
    assert_equal filled["exp_date"], off["exp_date"]
    assert_equal filled["cvv"], off["cvv"]
  end

  # --- Then: кнопка «Оплатить» активна при валидной форме ------------------

  test "S1 Then: isPayEnabled true only when PAN+exp+CVV valid" do
    empty = js_call("createNewCardFormState")
    assert_equal false, js_call("isPayEnabled", empty)

    partial = js_eval(<<~JS)
      let s = form.createNewCardFormState();
      s = form.applyPanInput(s, #{VALID_PAN.inspect});
      return s;
    JS
    assert_equal false, js_call("isPayEnabled", partial)

    filled = fill_valid_form
    assert_equal true, js_call("isPayEnabled", filled),
      "Шаг 1: при валидных PAN (Луна) + ММ/ГГ + CVV кнопка «Оплатить» активна"

    bad_luhn = js_eval(<<~JS)
      let s = form.createNewCardFormState();
      s = form.applyPanInput(s, "4111111111111112");
      s = form.applyExpInput(s, "0927");
      s = form.applyCvvInput(s, "123");
      return s;
    JS
    assert_equal false, js_call("isPayEnabled", bad_luhn)
  end

  test "S1 Then: filled form keeps save_card true in state" do
    filled = fill_valid_form
    assert_equal true, filled["save_card"]
    assert_equal true, js_call("isPayEnabled", filled)
  end

  # --- Then: Network snapshot без открытого PAN/CVV ------------------------

  test "S1 Then: formNetworkSnapshot never exposes open PAN or CVV" do
    filled = fill_valid_form
    snap = js_call("formNetworkSnapshot", filled)

    assert_equal true, snap["save_card"]
    assert_equal "09/27", snap["exp_date"]
    # маска последних 4 — не полный PAN
    assert_equal "*1111", snap["pan_mask"]
    refute snap.key?("pan"), "Network snapshot не должен содержать ключ pan"
    refute snap.key?("cvv"), "Network snapshot не должен содержать ключ cvv"
    refute snap.key?("pan_digits"), "Network snapshot не должен содержать pan_digits"
    refute snap.key?("CardData"), "Шаг 1: CardData ещё не шифруем — ключа быть не должно"
    json = JSON.generate(snap)
    refute_includes json, VALID_PAN
    refute_includes json, "4111111111111111"
    refute_includes json, VALID_CVV
    refute_match(/\b1111111111111111\b/, json)
  end

  test "S1 Then: UI wires save toggle and pay gate from lib" do
    lib = File.read(LIB)
    ui = File.read(UI)

    assert_includes ui, "shopNewCardForm"
    assert_match(/isPayEnabled|save_card/, ui)
    assert_includes lib, "save_card"
  end

  private

  def fill_valid_form
    js_eval(<<~JS)
      let s = form.createNewCardFormState();
      s = form.applyPanInput(s, #{VALID_PAN.inspect});
      s = form.applyExpInput(s, "0927");
      s = form.applyCvvInput(s, #{VALID_CVV.inspect});
      return s;
    JS
  end

  def js_call(fn, *args)
    args_js = args.map { |a| JSON.generate(a) }.join(", ")
    js_eval("return form.#{fn}(#{args_js});")
  end

  def js_eval(body)
    unless File.exist?(LIB)
      flunk "Шаг 1 Red: отсутствует #{LIB} — сначала падаем, потом реализуем"
    end

    # Windows ESM: только file:// или relative path от cwd (не raw C:\…)
    import_path = "./#{LIB.relative_path_from(Rails.root).to_s.tr('\\', '/')}"

    script = <<~JS
      import * as form from #{import_path.inspect};
      const result = (() => { #{body} })();
      process.stdout.write(JSON.stringify(result === undefined ? null : result));
    JS

    stdout, stderr, status = Open3.capture3(
      "node", "--input-type=module", "-e", script,
      chdir: Rails.root.to_s
    )
    unless status.success?
      flunk "Node eval failed (#{status.exitstatus}): #{stderr.presence || stdout}"
    end

    JSON.parse(stdout)
  end
end
