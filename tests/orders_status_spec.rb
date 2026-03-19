require 'rails_helper'

RSpec.describe 'Orders and Statuses', type: :integration do
  let(:tenant) { create(:tenant) }
  let(:product) { create(:product) }
  let(:ingredient) { create(:ingredient) }
  let(:stock) { create(:ingredient_tenant_stock, ingredient: ingredient, qty: 10) }
  let(:recipe) { create(:product_recipe, product: product, ingredient: ingredient, qty_per_serving: 2) }
  let(:order) { create(:order, tenant: tenant, status: 'pending') }

  before do
    Current.tenant_id = tenant.id
  end

  it 'auto-deducts ingredients on order accept' do
    order.update(status: 'accepted')
    stock.reload
    expect(stock.qty).to eq(8)
  end

  it 'transitions order statuses correctly' do
    order.update(status: 'accepted')
    order.update(status: 'preparing')
    order.update(status: 'ready')
    expect(order.status).to eq('ready')
  end

  it 'blocks changes after payment' do
    order.update(payment_status: 'paid')
    expect { order.update(status: 'cancelled') }.to raise_error(ActiveRecord::RecordInvalid)
  end

  it 'returns ingredients on order cancel' do
    order.update(status: 'accepted')
    order.update(status: 'cancelled')
    stock.reload
    expect(stock.qty).to eq(10)
  end
end