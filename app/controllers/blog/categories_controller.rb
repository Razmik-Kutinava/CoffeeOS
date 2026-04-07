# frozen_string_literal: true

module Blog
  class CategoriesController < Blog::ApplicationController
    def show
      @category = BlogCategory.find_by!(slug: params[:slug])
      scope = @category.blog_posts.includes(:blog_category)
      @posts =
        if blog_editor?
          scope.recent_first
        else
          scope.published.recent_first
        end
    end
  end
end
