# frozen_string_literal: true

require "test_helper"
load Rails.root.join("lib/tasks/fly_release.rake")

class FlyReleaseTest < ActiveSupport::TestCase
  test "migration_files_for queue is empty (only .keep)" do
    assert_empty FlyRelease.migration_files_for("queue")
  end

  test "migration_files_for cable is empty (only .keep)" do
    assert_empty FlyRelease.migration_files_for("cable")
  end

  test "migration_files_for cache includes solid_cache index migration" do
    files = FlyRelease.migration_files_for("cache")
    assert files.any? { |f| f.end_with?("ensure_solid_cache_key_hash_unique_index.rb") }
  end

  test "SolidSchemaConnection is a named ActiveRecord base" do
    assert_equal ActiveRecord::Base, FlyRelease::SolidSchemaConnection.superclass
    assert_predicate FlyRelease::SolidSchemaConnection, :abstract_class?
  end
end
