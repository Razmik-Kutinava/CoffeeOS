# frozen_string_literal: true

module Blog
  # ABAC-007: blog editor role gate.
  class PostPolicy < ApplicationPolicy
    def create?
      blog_editor?
    end

    alias_method :new?, :create?
    alias_method :update?, :create?
    alias_method :edit?, :create?
    alias_method :destroy?, :create?

    private

    def blog_editor?
      user.has_role_in_context?("blog_editor")
    end
  end
end
