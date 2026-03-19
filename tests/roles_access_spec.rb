require 'rails_helper'

RSpec.describe 'Roles and Access', type: :integration do
  let(:tenant) { create(:tenant) }
  let(:barista) { create(:user, roles: [create(:role, name: 'barista')]) }
  let(:admin) { create(:user, roles: [create(:role, name: 'admin')]) }
  let(:prep_worker) { create(:user, roles: [create(:role, name: 'prep_kitchen_worker')]) }
  let(:prep_manager) { create(:user, roles: [create(:role, name: 'prep_kitchen_manager')]) }

  before do
    Current.tenant_id = tenant.id
  end

  it 'redirects barista to barista dashboard' do
    sign_in barista
    get root_path
    expect(response).to redirect_to(barista_dashboard_path)
  end

  it 'redirects admin to admin dashboard' do
    sign_in admin
    get root_path
    expect(response).to redirect_to(admin_dashboard_path)
  end

  it 'redirects prep_kitchen_worker to prep_kitchen dashboard' do
    sign_in prep_worker
    get root_path
    expect(response).to redirect_to(prep_kitchen_dashboard_path)
  end

  it 'redirects prep_kitchen_manager to prep_kitchen dashboard' do
    sign_in prep_manager
    get root_path
    expect(response).to redirect_to(prep_kitchen_dashboard_path)
  end

  it 'denies access to admin routes for barista' do
    sign_in barista
    get admin_dashboard_path
    expect(response).to redirect_to(root_path)
    expect(flash[:alert]).to eq('Доступ запрещен для вашей роли')
  end

  it 'allows prep_manager to create stock movement' do
    sign_in prep_manager
    post prep_kitchen_inventory_path, params: { stock_movement: { movement_type: 'receipt' } }
    expect(response).to be_successful
  end

  it 'denies prep_worker to create stock movement' do
    sign_in prep_worker
    post prep_kitchen_inventory_path, params: { stock_movement: { movement_type: 'receipt' } }
    expect(response).to redirect_to(prep_kitchen_inventory_path)
    expect(flash[:alert]).to eq('Только менеджер может редактировать')
  end
end