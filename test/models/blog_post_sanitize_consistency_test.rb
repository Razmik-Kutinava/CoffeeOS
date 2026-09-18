# frozen_string_literal: true

require "test_helper"

# TASK_93-K T-K1: Blog show sanitize = BlogPost allowlists only.
class BlogPostSanitizeConsistencyTest < ActionDispatch::IntegrationTest
  test "T-K1a show template uses BlogPost::ALLOWED_TAGS not a wider inline list" do
    erb = File.read(Rails.root.join("app/views/blog/posts/show.html.erb"))
    sanitize_line = erb.lines.find { |line| line.include?("sanitize(@post.body") }

    assert sanitize_line, "expected sanitize(@post.body ...) in show template"
    assert_match(/BlogPost::ALLOWED_TAGS/, sanitize_line)
    assert_match(/BlogPost::ALLOWED_ATTRIBUTES/, sanitize_line)
    refute_match(/%w\[/, sanitize_line, "sanitize must not use an inline %w allowlist")
  end

  test "T-K1b before_save sanitizer strips img and h1" do
    post = BlogPost.create!(
      title: "Sanitize #{SecureRandom.hex(3)}",
      slug: "sanitize-#{SecureRandom.hex(4)}",
      body: '<p>ok</p><img src="https://evil.example/x.png"><h1>bad</h1>',
      published_at: Time.current
    )

    assert_includes post.body, "<p>ok</p>"
    refute_match(/<img/i, post.body)
    refute_match(/<h1/i, post.body)
  end

  test "T-K1c show does not re-introduce disallowed tags from raw DB body" do
    post = BlogPost.create!(
      title: "Render #{SecureRandom.hex(3)}",
      slug: "render-#{SecureRandom.hex(4)}",
      body: "<p>safe</p>",
      published_at: Time.current
    )
    post.update_columns(
      body: '<p>safe</p><img src="https://evil.example/x.png" style="x:1"><h1>sneak</h1>'
    )

    get blog_post_path(post)
    assert_response :success
    refute_match(/<img/i, response.body)
    refute_match(%r{<h1[^>]*>sneak</h1>}i, response.body)
    refute_includes response.body, 'style="x:1"'
    assert_includes response.body, "safe"
  end
end
