# frozen_string_literal: true

module PrepKitchen
  class QueuePolicy < BasePolicy
    def index?
      prep_staff?
    end
  end
end
