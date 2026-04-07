# frozen_string_literal: true

class CreateBlogTables < ActiveRecord::Migration[8.1]
  def change
    create_table :blog_categories, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.integer :sort_order, default: 0, null: false
      t.text :description

      t.timestamps
    end
    add_index :blog_categories, :slug, unique: true

    create_table :blog_posts, id: :uuid, default: -> { "gen_random_uuid()" } do |t|
      t.references :blog_category, null: true, foreign_key: true, type: :uuid
      t.string :title, null: false
      t.string :slug, null: false
      t.text :intro
      t.text :body
      t.text :conclusion
      t.string :meta_title
      t.string :meta_description, limit: 500
      t.string :cover_image_url, limit: 2048
      t.datetime :published_at
      t.integer :position, default: 0, null: false

      t.timestamps
    end
    add_index :blog_posts, :slug, unique: true
    add_index :blog_posts, :published_at
  end
end
