# frozen_string_literal: true

module Blog
  class PostsController < Blog::ApplicationController
    before_action :require_blog_editor!, except: %i[show]
    before_action :set_post, only: %i[show edit update destroy]
    before_action :set_categories, only: %i[new edit create update]

    def show
      return if @post.published? || blog_editor?

      raise ActiveRecord::RecordNotFound
    end

    def new
      @post = BlogPost.new(publish: "1")
      @post.blog_category_id = params[:blog_category_id].presence
    end

    def create
      @post = BlogPost.new(post_params)
      if @post.save
        redirect_to blog_post_path(@post), notice: "Статья сохранена."
      else
        render :new, status: :unprocessable_entity
      end
    end

    def edit
      @post.publish = @post.published?
    end

    def update
      if @post.update(post_params)
        redirect_to blog_post_path(@post), notice: "Статья обновлена."
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @post.destroy!
      redirect_to blog_root_path, notice: "Статья удалена."
    end

    private

    def set_post
      @post = BlogPost.includes(:blog_category).find_by!(slug: params[:slug])
    end

    def post_params
      params.require(:blog_post).permit(
        :title, :slug, :intro, :body, :conclusion,
        :meta_title, :meta_description, :cover_image_url,
        :blog_category_id, :publish
      )
    end

    def require_blog_editor!
      return if blog_editor?

      redirect_to blog_root_path, alert: "Нужны права редактора блога."
    end

    def set_categories
      @categories = BlogCategory.ordered
    end
  end
end
