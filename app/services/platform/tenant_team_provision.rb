# frozen_string_literal: true

module Platform
  # Команда точки из карточки УК: реальные аккаунты с ролями точки, пароли генерируются и возвращаются один раз.
  # Всё или ничего: одна ошибка (занятый email, чужая роль) — никто не создаётся.
  class TenantTeamProvision
    Error = Class.new(StandardError)

    SALES_ROLES = %w[general_manager barista shift_manager].freeze
    KITCHEN_ROLES = %w[prep_kitchen_manager prep_kitchen_worker].freeze
    ROLE_LABELS = {
      "general_manager" => "Менеджер",
      "barista" => "Бариста",
      "shift_manager" => "Менеджер смены",
      "prep_kitchen_manager" => "Менеджер цеха",
      "prep_kitchen_worker" => "Работник цеха"
    }.freeze

    def self.allowed_roles(tenant)
      tenant.production_kitchen? ? KITCHEN_ROLES : SALES_ROLES
    end

    def self.call(tenant:, members:)
      new(tenant: tenant, members: members).call
    end

    def initialize(tenant:, members:)
      @tenant = tenant
      @rows = Array(members).map { |m| normalize(m) }.reject { |r| r[:email].blank? && r[:phone].blank? }
    end

    def call
      raise Error, "Добавьте хотя бы одного сотрудника (email или телефон)" if @rows.empty?

      allowed = self.class.allowed_roles(@tenant)
      bad = @rows.find { |r| !allowed.include?(r[:role]) }
      raise Error, "Роль «#{bad[:role]}» недоступна для этой точки" if bad

      credentials = []
      ActiveRecord::Base.transaction do
        @rows.each { |row| credentials << create_member!(row) }
      end
      credentials
    rescue ActiveRecord::RecordNotUnique
      raise Error, "Email или телефон уже занят"
    end

    private

    def normalize(member)
      h = member.respond_to?(:to_unsafe_h) ? member.to_unsafe_h : member.to_h
      h = h.stringify_keys
      {
        role: h["role"].to_s,
        name: h["name"].to_s.strip,
        email: h["email"].to_s.strip.downcase.presence,
        phone: h["phone"].to_s.strip.presence
      }
    end

    def create_member!(row)
      password = SecureRandom.alphanumeric(10)
      user = User.new(
        name: row[:name].presence || ROLE_LABELS.fetch(row[:role], row[:role]),
        email: row[:email],
        phone: row[:phone],
        tenant_id: @tenant.id,
        organization_id: @tenant.organization_id,
        status: "active",
        password: password
      )
      raise Error, "#{row[:email] || row[:phone]}: #{user.errors.full_messages.to_sentence}" unless user.save

      role = Role.find_or_create_by!(code: row[:role]) { |r| r.name = ROLE_LABELS.fetch(row[:role], row[:role]) }
      UserRole.create!(user: user, role: role, tenant_id: @tenant.id)

      { "role" => row[:role], "name" => user.name, "login" => user.email || user.phone, "password" => password }
    end
  end
end
