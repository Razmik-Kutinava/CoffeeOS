require_relative "bundle_env"
AppBundleEnv.apply!(ENV)

require "bundler/setup" # Set up gems listed in the Gemfile.
require "bootsnap/setup" # Speed up boot time by caching expensive operations.
