# frozen_string_literal: true

module Platform
  # #77: УК — point-scoped subscription offer settings (вторая CTA + пороги).
  class SubscriptionOfferSettingsController < BaseController
    before_action :set_tenant

    def show
      authorize @tenant, :show?
      render json: setting_json
    end

    def edit
      authorize @tenant, :update?
      @setting = find_or_build_setting
    end

    def update
      authorize @tenant, :update?
      @setting = find_or_build_setting
      attrs = setting_params

      if attrs[:required_signals_count].present?
        count = attrs[:required_signals_count].to_i
        unless (1..3).cover?(count)
          return render json: { error: "required_signals_count must be 1..3" }, status: :bad_request
        end
      end

      @setting.assign_attributes(attrs)
      if @setting.save
        respond_to do |format|
          format.json { render json: setting_json(@setting) }
          format.html { redirect_to edit_platform_tenant_subscription_offer_setting_path(@tenant), notice: "Настройки оффера сохранены" }
        end
      else
        respond_to do |format|
          format.json { render json: { error: @setting.errors.full_messages.to_sentence }, status: :bad_request }
          format.html { render :edit, status: :unprocessable_entity }
        end
      end
    end

    private

    def set_tenant
      @tenant = Tenant.find(params[:tenant_id])
    end

    def find_or_build_setting
      SubscriptionOfferSetting.find_by(point_id: @tenant.id) ||
        SubscriptionOfferSetting.new(SubscriptionOfferSetting.defaults_hash.merge(point_id: @tenant.id))
    end

    def setting_params
      params.require(:subscription_offer_setting).permit(
        :enabled, :second_cta_mode, :min_completed_orders, :required_signals_count
      )
    end

    def setting_json(setting = nil)
      setting ||= SubscriptionOfferSetting.for_point(@tenant.id)
      if setting&.persisted?
        {
          enabled: setting.enabled?,
          second_cta_mode: setting.second_cta_mode,
          min_completed_orders: setting.min_completed_orders,
          required_signals_count: setting.required_signals_count
        }
      else
        SubscriptionOfferSetting.defaults_hash
      end
    end
  end
end
