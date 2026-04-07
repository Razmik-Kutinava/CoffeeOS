# frozen_string_literal: true

module Blog
  class HomeController < Blog::ApplicationController
    def index
      @categories = BlogCategory.ordered
      @hero_title = "CoffeeOS — блог"
      @hero_subtitle = "Заметки о кофе, точках и продукте."

      scope = BlogPost.includes(:blog_category)
      @latest_posts =
        if blog_editor?
          scope.recent_first.limit(12)
        else
          scope.published.recent_first.limit(12)
        end

      @draft_posts = BlogPost.draft.includes(:blog_category).recent_first.limit(8) if blog_editor?
    end
  end
end
