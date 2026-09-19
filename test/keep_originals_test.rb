require "test_helper"

class KeepOriginalsTest < Minitest::Test
  include SiteHelpers

  KEEP = { "compress_images" => { "overwrite_originals" => false } }.freeze

  def test_leaves_the_source_image_untouched
    image = add_image("assets/img/a.png")
    run_plugin(FakeOptimizer.new, KEEP)

    assert_equal "image-assets/img/a.png", File.read(image)
    refute File.exist?(File.join(@source, "_compress_images_cache.yml"))
  end

  def test_optimizes_each_image_only_once
    add_image("assets/img/a.png")
    run_plugin(FakeOptimizer.new, KEEP)

    assert_empty run_plugin(FakeOptimizer.new, KEEP).calls
  end

  def test_publishes_the_optimized_copy
    add_image("assets/img/a.png")
    run_plugin(FakeOptimizer.new, KEEP)
    file = @last_site.static_files.find { |f| f.url == "/assets/img/a.png" }

    assert_equal "image-assets/img/a.png\0", File.read(file.path)
  end

  def test_a_failed_image_is_published_as_is
    add_image("assets/img/bad.png")
    run_plugin(FakeOptimizer.new(fail_on: ".tmp.png"), KEEP)
    file = @last_site.static_files.find { |f| f.url == "/assets/img/bad.png" }

    assert_equal source_path("assets/img/bad.png"), file.path
    assert_empty cache_dir_files
  end

  def test_removes_cached_copies_of_deleted_images
    add_image("assets/img/a.png")
    removed = add_image("assets/img/b.png")
    run_plugin(FakeOptimizer.new, KEEP)
    assert_equal 2, cache_dir_files.size

    File.delete(removed)
    run_plugin(FakeOptimizer.new, KEEP)

    assert_equal 1, cache_dir_files.size
  end

  def test_real_build_writes_a_smaller_image_to_site_only
    image = add_image("assets/img/real.png", uncompressed_png)
    original = File.binread(image)
    build(KEEP)

    assert_equal original, File.binread(image)
    assert_operator File.size(site_path("assets/img/real.png")), :<, original.bytesize
  end

  def test_real_rebuild_keeps_the_optimized_image
    add_image("assets/img/real.png", uncompressed_png)
    build(KEEP)
    optimized = File.binread(site_path("assets/img/real.png"))
    build(KEEP)

    assert_equal optimized, File.binread(site_path("assets/img/real.png"))
  end
end
