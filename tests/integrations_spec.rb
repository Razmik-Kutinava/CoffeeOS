require 'rails_helper'

RSpec.describe 'Integrations Between Modules', type: :integration do
  let(:tenant) { create(:tenant) }
  let(:admin) { create(:user, roles: [create(:role, name: 'admin')]) }
  let(:barista) { create(:user, roles: [create(:role, name: 'barista')]) }
  let(:prep_manager) { create(:user, roles: [create(:role, name: 'prep_kitchen_manager')]) }
  let(:product) { create(:product, tenant: tenant) }

  before do
    Current.tenant_id = tenant.id
  end

  it 'barista sees menu changes' do
    sign_in admin
    product.update(name: 'New Name')
    sign_in barista
    get barista_dashboard_path
    expect(response.body).to include('New Name')
  end

  it 'manager sees kitchen statuses' do
    order = create(:order, tenant: tenant, status: 'accepted')
    sign_in prep_manager
    get prep_kitchen_queue_path
    expect(response.body).to include(order.id.to_s)
  end

  it 'admin sees global ingredients' do
    ingredient = create(:ingredient)
    sign_in admin
    get admin_dashboard_path
    expect(response.body).to include(ingredient.name)
  end

  it 'device integration displays orders' do
    device = create(:device, tenant: tenant)
    order = create(:order, tenant: tenant, device: device)
    get api_orders_path, params: { device_id: device.id }
    expect(JSON.parse(response.body).first['id']).to eq(order.id)
  end

  it 'shift closure generates reports' do
    shift = create(:shift, tenant: tenant)
    sign_in prep_manager
    post close_shift_path(shift), params: { inventory_data: {} }
    expect(shift.reload.closed_at).to be_present
  end
end