# frozen_string_literal: true

# До Bundler.setup выставляем абсолютные BUNDLE_GEMFILE и BUNDLE_PATH.
#
# WSL + клон на /mnt/c|d/... (drvfs): гемы в ./vendor/bundle часто ставятся «успешно»,
# но Ruby/Bundler их не видит (симлинки, метаданные). Кладём bundle на ext4 в ~/.
module AppBundleEnv
  def self.apply!(env = ENV)
    root = File.expand_path("..", __dir__)
    env["BUNDLE_GEMFILE"] = File.join(root, "Gemfile")
    # In Docker/production BUNDLE_PATH is already set via ENV in the Dockerfile
    # (/usr/local/bundle). Don't override it — gems are installed there.
    env["BUNDLE_PATH"] = bundle_path_for(root) unless env["BUNDLE_PATH"]
  end

  def self.bundle_path_for(root)
    if wsl_repo_on_drvfs?(root)
      slug = root.sub(%r{\A/mnt/}, "mnt_").tr("/", "_")
      File.join(Dir.home, ".local", "share", "coffeeos-vendor", slug)
    else
      File.join(root, "vendor", "bundle")
    end
  end

  def self.wsl_repo_on_drvfs?(root)
    return false unless root.start_with?("/mnt/")
    return false unless RUBY_PLATFORM.include?("linux")

    v = File.read("/proc/version")
    v.downcase.include?("microsoft")
  rescue StandardError
    false
  end
end
