# frozen_string_literal: true

# TASK_115: явное членство точки в сети CODE:BLACK. По умолчанию false — существующие
# точки при выкладке в сеть не входят, владелец отмечает их сам (R6, 2026-10-21).
# Только торговая точка может быть в сети — проверка и в БД, и в модели.
class AddCodeBlackMemberToTenants < ActiveRecord::Migration[8.0]
  CHECK_NAME = "chk_tenants_code_black_member_sales_point"

  def up
    add_column :tenants, :code_black_member, :boolean, default: false, null: false
    add_check_constraint :tenants, "NOT code_black_member OR type = 'sales_point'", name: CHECK_NAME
  end

  def down
    remove_check_constraint :tenants, name: CHECK_NAME
    remove_column :tenants, :code_black_member
  end
end
