require 'rails_helper'

RSpec.describe 'Prep Kitchen and Stock', type: :integration do
  let(:tenant) { create(:tenant) }
  let(:ingredient) { create(:ingredient) }
  let(:stock) { create(:ingredient_tenant_stock, ingredient: ingredient, qty: 5) }
  let(:product) { create(:product) }
  let(:recipe) { create(:product_recipe, product: product, ingredient: ingredient, qty_per_serving: 2) }
  let(:order) { create(:order, tenant: tenant, status: 'pending') }

  before do
    Current.tenant_id = tenant.id
  end

  it 'auto-deducts with modifiers' do
    modifier = create(:modifier_option_recipe, ingredient: ingredient, qty_change: 1)
    order.update(status: 'accepted')
    stock.reload
    expect(stock.qty).to eq(4) # 5 - 2 (base) - 1 (modifier)
  end

  it 'sets stop list on zero stock' do
    stock.update(qty: 0)
    expect(product.reload.sold_out_reason).to eq('stock_empty')
  end

  it 'allows manager to create receipt' do
    manager = create(:user, roles: [create(:role, name: 'prep_kitchen_manager')])
    sign_in manager
    post prep_kitchen_inventory_path, params: { stock_movement: { movement_type: 'receipt', stock_movement_items_attributes: [{ ingredient_id: ingredient.id, qty_change: 10 }] } }
    expect(StockMovement.last.status).to eq('confirmed')
  end

  it 'performs inventory correctly' do
    movement = create(:stock_movement, movement_type: 'inventory', tenant: tenant)
    create(:stock_movement_item, stock_movement: movement, ingredient: ingredient, qty_change: 5)
    movement.confirm!
    stock.reload
    expect(stock.qty).to eq(5)
  end
end