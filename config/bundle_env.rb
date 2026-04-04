# frozen_string_literal: true

# Фиксируем абсолютные пути до Bundler.setup.
# На WSL с репозиторием на /mnt/c/ (drvfs) относительный BUNDLE_PATH из .bundle/config
# иногда не совпадает с каталогом, откуда Ruby ищет гемы после bundle install.
module AppBundleEnv
  def self.apply!(env = ENV)
    root = File.expand_path("..", __dir__)
    env["BUNDLE_GEMFILE"] = File.join(root, "Gemfile")
    env["BUNDLE_PATH"] = File.join(root, "vendor", "bundle")
  end
end
