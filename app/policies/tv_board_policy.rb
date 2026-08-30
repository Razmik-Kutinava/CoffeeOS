# frozen_string_literal: true

# ABAC-057: TV board access via device token.
class TvBoardPolicy
  def initialize(token:)
    @auth = Devices::DeviceAuthPolicy.new(token: token, device_type: "tv_board")
  end

  def show?
    @auth.authenticate?
  end

  def device
    @auth.device
  end
end
