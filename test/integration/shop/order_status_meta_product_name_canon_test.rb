# frozen_string_literal: true

require "test_helper"

# #35 D2 — скрин 06: мета «… — название позиции (только продукта)» в expanded-контексте.
class Shop::OrderStatusMetaProductNameCanonTest < ActionDispatch::IntegrationTest
  def accordion_js
    @accordion_js ||= File.read(Rails.root.join("app/frontend/lib/activeOrdersAccordion.js"))
  end

  def accordion_svelte
    @accordion_svelte ||= File.read(Rails.root.join("app/frontend/components/ActiveOrdersAccordion.svelte"))
  end

  test "statusMetaThird exported for peek vs cart_expanded contexts" do
    assert_match(/export function statusMetaThird/, accordion_js)
    assert_includes accordion_js, "cart_expanded"
    assert_match(/items\[0\].*(name|product_name)|product_name|firstItem/m, accordion_js)
  end

  test "ActiveOrdersAccordion renders metaThird in status meta line" do
    assert_includes accordion_svelte, "metaThird",
      "#35 D2: UI должен показывать metaThird (позиция), не только salesPointName"
  end
end
