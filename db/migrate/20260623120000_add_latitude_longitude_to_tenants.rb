# frozen_string_literal: true

# B1.14-3b: координаты точки для сортировки дропдауна «ближайшие в городе».
class AddLatitudeLongitudeToTenants < ActiveRecord::Migration[8.0]
  def change
    change_table :tenants, bulk: true do |t|
      t.decimal :latitude, precision: 10, scale: 7
      t.decimal :longitude, precision: 10, scale: 7
    end

    add_index :tenants, %i[city status type], name: "index_tenants_on_city_status_type"
  end
end
