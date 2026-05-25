# frozen_string_literal: true

namespace :demo do
  desc "Демо-среда В1: 1 org, 2 точки продаж, заготовочный цех, каталог, PTS, пользователи с ролями"
  task seed: :environment do
    load Rails.root.join("db/seeds_demo_v1.rb")
  end
end
