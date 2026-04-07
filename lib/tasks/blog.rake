# frozen_string_literal: true

namespace :blog do
  desc "Создать демо-рубрики и статьи блога (идемпотентно)"
  task seed: :environment do
    unless ActiveRecord::Base.connection.data_source_exists?("blog_categories")
      abort "Сначала выполните: bin/rails db:migrate"
    end

    cat_news = BlogCategory.find_or_create_by!(slug: "novosti") do |c|
      c.name = "Новости"
      c.sort_order = 0
      c.description = "Новости CoffeeOS и точек."
    end

    cat_guides = BlogCategory.find_or_create_by!(slug: "guides") do |c|
      c.name = "Гайды"
      c.sort_order = 1
      c.description = "Как пользоваться продуктом и витриной."
    end

    unless BlogPost.exists?(slug: "dobro-pozhalovat-v-blog-coffeeos")
      BlogPost.create!(
        blog_category: cat_news,
        title: "Добро пожаловать в блог CoffeeOS",
        slug: "dobro-pozhalovat-v-blog-coffeeos",
        intro: "Это демо-статья: вступление кратко объясняет, о чём текст.",
        body: <<~HTML,
          <p>Основной текст поддерживает <strong>жирный</strong>, <em>курсив</em>, списки и подзаголовки.</p>
          <h2>Подзаголовок H2</h2>
          <ul>
            <li>Пункт списка</li>
            <li>Ещё один</li>
          </ul>
          <blockquote>Цитата или важная мысль в блоке.</blockquote>
          <h3>H3 для деталей</h3>
          <p>Текст после санитайза остаётся безопасным.</p>
        HTML
        conclusion: "Мы показали вступление, тело и выводы — так читателю проще следовать за мыслью.",
        meta_title: "Блог CoffeeOS — первая статья",
        meta_description: "Демонстрация разметки и блоков блога CoffeeOS.",
        published_at: Time.current
      )
    end

    unless BlogPost.exists?(slug: "kak-rabotayet-vitrina")
      BlogPost.create!(
        blog_category: cat_guides,
        title: "Как работает витрина",
        slug: "kak-rabotayet-vitrina",
        intro: "Коротко о заказе и каталоге.",
        body: "<p>Откройте <strong>/shop</strong> и выберите точку. Корзина и заказ — как в обычном приложении.</p>",
        conclusion: "Попробуйте оформить тестовый заказ в dev.",
        published_at: Time.current
      )
    end

    puts "✓ Блог: рубрики «#{cat_news.name}», «#{cat_guides.name}», демо-статьи (если ещё не были созданы)."
  end
end
