require 'rails_helper'
require 'benchmark'

RSpec.describe 'Load Tests', type: :request do
  let(:tenant) { create(:tenant) }

  before do
    Current.tenant_id = tenant.id
  end

  it 'handles 1000 simultaneous orders' do
    threads = []
    time = Benchmark.realtime do
      1000.times do |i|
        threads << Thread.new do
          post orders_path, params: { order: { items: [{ product_id: create(:product).id }] } }
        end
      end
      threads.each(&:join)
    end
    expect(time).to be < 50 # Less than 50 seconds for 1000 orders
    expect(Order.count).to eq(1000)
  end

  it 'processes 5000 stock movements' do
    ingredient = create(:ingredient)
    time = Benchmark.realtime do
      5000.times do
        create(:stock_movement, movement_type: 'receipt', tenant: tenant, stock_movement_items_attributes: [{ ingredient_id: ingredient.id, qty_change: 1 }])
      end
    end
    expect(time).to be < 30
    expect(StockMovement.count).to eq(5000)
  end

  it 'manages queue under load' do
    100.times { create(:order, tenant: tenant, status: 'accepted') }
    get prep_kitchen_queue_path
    expect(response).to be_successful
    expect(JSON.parse(response.body)['orders'].size).to eq(100)
  end

  it 'updates 1000 stocks in inventory' do
    ingredients = 1000.times.map { create(:ingredient) }
    stocks = ingredients.map { |i| create(:ingredient_tenant_stock, ingredient: i, qty: 10) }
    time = Benchmark.realtime do
      post inventory_path, params: { inventory: stocks.map { |s| { id: s.id, qty: 15 } } }
    end
    expect(time).to be < 10
    stocks.each { |s| expect(s.reload.qty).to eq(15) }
  end
end