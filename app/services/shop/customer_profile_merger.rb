# frozen_string_literal: true

module Shop
  # Мягкое слияние двух MobileCustomer: donor → survivor, без destroy.
  class CustomerProfileMerger
    class Error < StandardError; end

    def self.merge!(survivor:, donor:)
      new(survivor: survivor, donor: donor).merge!
    end

    def self.link_email!(survivor:, email:)
      new(survivor: survivor).link_email!(email)
    end

    def self.link_phone!(survivor:, phone:)
      new(survivor: survivor).link_phone!(phone)
    end

    def initialize(survivor:, donor: nil)
      @survivor = survivor
      @donor = donor
    end

    def merge!
      raise Error, "Нет целевого профиля" if @survivor.blank?
      raise Error, "Нет профиля-донора" if @donor.blank?
      return @survivor if @survivor.id == @donor.id

      ActiveRecord::Base.transaction do
        lock_pair!
        absorb_contacts!
        reassign_foreign_keys!
        soft_deactivate_donor!
        @survivor.save!
      end
      @survivor.reload
    rescue ActiveRecord::RecordInvalid => e
      raise Error, e.record.errors.full_messages.to_sentence.presence || e.message
    end

    def link_email!(email)
      normalized = EmailVerificationSession.normalize(email)
      raise Error, "Укажите email" if normalized.blank?

      ActiveRecord::Base.transaction do
        @survivor.lock!
        other = MobileCustomer.where(email: normalized).where.not(id: @survivor.id).lock.first
        if other
          @donor = other
          absorb_contacts!
          reassign_foreign_keys!
          soft_deactivate_donor!
        end
        @survivor.email = normalized
        @survivor.email_verified = true
        @survivor.is_active = true
        @survivor.save!
      end
      @survivor.reload
    rescue ActiveRecord::RecordInvalid => e
      raise Error, e.record.errors.full_messages.to_sentence.presence || e.message
    end

    def link_phone!(phone)
      normalized = PhoneNormalizer.normalize!(phone)

      ActiveRecord::Base.transaction do
        @survivor.lock!
        other = MobileCustomer.where(phone: normalized).where.not(id: @survivor.id).lock.first
        if other
          @donor = other
          absorb_contacts!
          reassign_foreign_keys!
          soft_deactivate_donor!
        end
        @survivor.phone = normalized
        @survivor.phone_verified = true
        @survivor.is_active = true
        @survivor.save!
      end
      @survivor.reload
    rescue PhoneNormalizer::Error => e
      raise Error, e.message
    rescue ActiveRecord::RecordInvalid => e
      raise Error, e.record.errors.full_messages.to_sentence.presence || e.message
    end

    private

    def lock_pair!
      first, second = [ @survivor, @donor ].sort_by(&:id)
      first.lock!
      second.lock!
      @survivor = MobileCustomer.find(@survivor.id)
      @donor = MobileCustomer.find(@donor.id)
    end

    def absorb_contacts!
      if @survivor.email.blank? && @donor.email.present?
        @survivor.email = @donor.email
        @survivor.email_verified = @donor.email_verified
      elsif @donor.email.present? && @donor.email_verified && !@survivor.email_verified
        @survivor.email_verified = true if @survivor.email == @donor.email
      end

      if @survivor.phone.blank? && @donor.phone.present?
        @survivor.phone = @donor.phone
        @survivor.phone_verified = @donor.phone_verified
      elsif @donor.phone.present? && @donor.phone_verified && !@survivor.phone_verified
        @survivor.phone_verified = true if @survivor.phone == @donor.phone
      end

      if @survivor.first_name.blank? || @survivor.first_name == "Гость"
        @survivor.first_name = @donor.first_name if @donor.first_name.present?
      end
      @survivor.last_name = @donor.last_name if @survivor.last_name.blank? && @donor.last_name.present?
    end

    def reassign_foreign_keys!
      Order.where(customer_id: @donor.id).update_all(customer_id: @survivor.id)
      MobilePaymentMethod.where(customer_id: @donor.id).find_each do |pm|
        if pm.is_default && MobilePaymentMethod.where(customer_id: @survivor.id, is_default: true, is_active: true).exists?
          pm.update_columns(customer_id: @survivor.id, is_default: false)
        else
          pm.update_columns(customer_id: @survivor.id)
        end
      end
      MobileSession.where(customer_id: @donor.id).update_all(customer_id: @survivor.id)
      PushNotification.where(customer_id: @donor.id).update_all(customer_id: @survivor.id)
      reassign_optional_table!("order_feedback")
      reassign_optional_table!("promo_code_usages")
      reassign_carts!
      reassign_loyalty!
    end

    def reassign_optional_table!(table)
      conn = ActiveRecord::Base.connection
      return unless conn.data_source_exists?(table)

      conn.execute(
        "UPDATE #{table} SET customer_id = #{conn.quote(@survivor.id)} " \
        "WHERE customer_id = #{conn.quote(@donor.id)}"
      )
    end

    def reassign_carts!
      return unless ActiveRecord::Base.connection.data_source_exists?("mobile_carts")

      MobileCart.where(customer_id: @donor.id).find_each do |donor_cart|
        survivor_cart = MobileCart.find_by(customer_id: @survivor.id, tenant_id: donor_cart.tenant_id)
        if survivor_cart
          merged = Array(survivor_cart.items) + Array(donor_cart.items)
          survivor_cart.update!(
            items: merged,
            total_amount: survivor_cart.total_amount.to_d + donor_cart.total_amount.to_d
          )
          donor_cart.destroy!
        else
          donor_cart.update!(customer_id: @survivor.id)
        end
      end
    end

    def reassign_loyalty!
      conn = ActiveRecord::Base.connection
      return unless conn.data_source_exists?("loyalty_accounts")

      donor_row = conn.select_one(
        "SELECT id FROM loyalty_accounts WHERE customer_id = #{conn.quote(@donor.id)} LIMIT 1"
      )
      return unless donor_row

      survivor_row = conn.select_one(
        "SELECT id FROM loyalty_accounts WHERE customer_id = #{conn.quote(@survivor.id)} LIMIT 1"
      )
      if survivor_row
        if conn.data_source_exists?("loyalty_transactions")
          conn.execute(
            "UPDATE loyalty_transactions SET customer_id = #{conn.quote(@survivor.id)} " \
            "WHERE customer_id = #{conn.quote(@donor.id)}"
          )
        end
        conn.execute("DELETE FROM loyalty_accounts WHERE id = #{conn.quote(donor_row['id'])}")
      else
        conn.execute(
          "UPDATE loyalty_accounts SET customer_id = #{conn.quote(@survivor.id)} " \
          "WHERE id = #{conn.quote(donor_row['id'])}"
        )
      end
    end

    def soft_deactivate_donor!
      # Освобождаем unique email/phone до save survivor (уже поглощены).
      @donor.email = nil
      @donor.phone = nil
      @donor.email_verified = false
      @donor.phone_verified = false
      @donor.is_active = false
      @donor.save!(validate: false)
    end
  end
end
