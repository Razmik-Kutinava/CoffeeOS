# frozen_string_literal: true

module PrepKitchen
  class ReportPolicy < BasePolicy
    def index?
      prep_manager?
    end
  end
end
