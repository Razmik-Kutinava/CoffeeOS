# frozen_string_literal: true

module Shop
  class BaseController < ApplicationController
    include Shop::Concerns::TenantResolution
  end
end
