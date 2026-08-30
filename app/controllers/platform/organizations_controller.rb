# frozen_string_literal: true

module Platform
  class OrganizationsController < BaseController
    def index
      authorize Organization
      @organizations = Organization.order(:name)
    end

    def new
      authorize Organization
      @organization = Organization.new
    end

    def create
      authorize Organization
      @organization = Organization.new(organization_params)
      if @organization.save
        redirect_to platform_organizations_path, notice: "Организация создана"
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      @organization = Organization.find(params[:id])
      authorize @organization
    end

    def update
      @organization = Organization.find(params[:id])
      authorize @organization
      if @organization.update(organization_params)
        redirect_to platform_organizations_path, notice: "Сохранено"
      else
        render :edit, status: :unprocessable_entity
      end
    end

    private

    def organization_params
      params.require(:organization).permit(:name, :slug)
    end
  end
end
