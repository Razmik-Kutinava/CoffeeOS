# frozen_string_literal: true

class AdminAuditLog < ApplicationRecord
  belongs_to :tenant
  belongs_to :actor, class_name: "User", optional: true

  validates :action, presence: true, length: { maximum: 50 }
  validates :entity_type, presence: true, length: { maximum: 100 }
  validates :tenant_id, presence: true

  scope :for_tenant, ->(tenant_id) { where(tenant_id: tenant_id) }
  scope :recent, -> { order(created_at: :desc) }

  def self.log(action:, actor:, entity:, tenant_id:, details: {}, request_id: nil)
    create!(
      action: action,
      actor_id: actor&.id,
      entity_id: entity&.id,
      entity_type: entity&.class&.name || "Unknown",
      tenant_id: tenant_id,
      details: details,
      request_id: request_id
    )
  end
end
