# frozen_string_literal: true

# Промокод для тестирования
PromoCode.create!(
  code: "coffeefree",
  discount_percentage: 100,
  is_active: true,
  valid_from: 1.day.ago,
  valid_to: 1.year.from_now,
  max_uses: 0,
  used_count: 0
) unless PromoCode.exists?(code: "coffeefree")
