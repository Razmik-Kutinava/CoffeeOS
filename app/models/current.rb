class Current < ActiveSupport::CurrentAttributes
  attribute :tenant_id, :user_id, :role_code
end
