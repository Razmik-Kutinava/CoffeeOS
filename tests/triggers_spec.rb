require 'rails_helper'

RSpec.describe 'Database Triggers', type: :integration do
  let(:tenant) { create(:tenant) }
  let(:ingredient) { create(:ingredient) }
  let(:stock) { create(:ingredient_tenant_stock, ingredient: ingredient, qty: 10) }
  let(:product) { create(:product) }
  let(:recipe) { create(:product_recipe, product: product, ingredient: ingredient, qty_per_serving: 2) }
  let(:order) { create(:order, tenant: tenant, status: 'pending') }

  before do
    Current.tenant_id = tenant.id
  end

  it 'auto_deduct_ingredients_on_order_accept triggers correctly' do
    order.update(status: 'accepted')
    stock.reload
    expect(stock.qty).to eq(8)
    expect(StockMovement.where(reference_id: order.id, movement_type: 'order_deduct').count).to eq(1)
  end

  it 'auto_stop_list_on_zero_stock triggers on qty=0' do
    stock.update(qty: 0)
    product.reload
    expect(product.sold_out_reason).to eq('stock_empty')
  end

  it 'handles modifiers in deduction' do
    modifier = create(:modifier_option_recipe, ingredient: ingredient, qty_change: 1)
    order.update(status: 'accepted')
    stock.reload
    expect(stock.qty).to eq(7) # 10 - 2 - 1
  end

  it 'creates return movement on cancel' do
    order.update(status: 'accepted')
    order.update(status: 'cancelled')
    expect(StockMovement.where(movement_type: 'return', reference_id: order.id).count).to eq(1)
    stock.reload
    expect(stock.qty).to eq(10)
  end
end