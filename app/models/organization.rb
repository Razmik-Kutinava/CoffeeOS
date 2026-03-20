# frozen_string_literal: true

class Organization < ApplicationRecord
  has_many :tenants, dependent: :restrict_with_error
  has_many :users, dependent: :nullify

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true, format: { with: /\A[a-z0-9][a-z0-9\-]*\z/, message: "только латиница, цифры и дефис" }
end
