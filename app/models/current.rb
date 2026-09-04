# frozen_string_literal: true

class Current < ActiveSupport::CurrentAttributes
  attribute :tenant_id, :user_id, :role_code

  # Assign without a block. Rails `Current.set(...)` requires `do … end`.
  # Use in one-shot runners / MCP scripts: Current.assign!(tenant_id: tid)
  def self.assign!(**attrs)
    attrs.each { |key, value| public_send(:"#{key}=", value) }
    self
  end
end
