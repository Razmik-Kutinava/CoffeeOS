class ShiftStaff < ApplicationRecord
  enum role_in_shift: { barista: 'barista', shift_manager: 'shift_manager' }

  belongs_to :shift
  belongs_to :user
  belongs_to :tenant

  validates :shift_id, uniqueness: { scope: :user_id }
  validates :role_in_shift, presence: true

  scope :active, -> { where(checked_out_at: nil) }
  scope :checked_out, -> { where.not(checked_out_at: nil) }

  def active?
    checked_out_at.nil?
  end

  def checkout!
    update!(checked_out_at: Time.current)
  end
end
