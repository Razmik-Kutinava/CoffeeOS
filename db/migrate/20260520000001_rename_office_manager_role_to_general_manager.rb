class RenameOfficeManagerRoleToGeneralManager < ActiveRecord::Migration[8.1]
  def up
    execute <<~SQL
      UPDATE roles SET code = 'general_manager', name = 'General Manager'
      WHERE code = 'office_manager';

      UPDATE user_roles ur
      SET role_id = (SELECT id FROM roles WHERE code = 'general_manager' LIMIT 1)
      WHERE ur.role_id IN (SELECT id FROM roles WHERE code = 'office_manager');
    SQL
  end

  def down
    execute <<~SQL
      UPDATE roles SET code = 'office_manager', name = 'Office Manager'
      WHERE code = 'general_manager';

      UPDATE user_roles ur
      SET role_id = (SELECT id FROM roles WHERE code = 'office_manager' LIMIT 1)
      WHERE ur.role_id IN (SELECT id FROM roles WHERE code = 'general_manager');
    SQL
  end
end
