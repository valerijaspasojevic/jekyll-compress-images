require "test_helper"

class CompressImagesTest < Minitest::Test
  include SiteHelpers

  def test_optimizes_images_and_caches_their_digest
    image = add_image("assets/img/a.png")
    optimizer = run_plugin

    assert_equal ["a.png"], basenames(optimizer.calls)
    assert_equal({ "assets/img/a.png" => Digest::SHA256.file(image).hexdigest }, cache)
  end

  def test_skips_images_that_are_already_optimized
    add_image("assets/img/a.png")
    run_plugin

    assert_empty run_plugin.calls
  end

  def test_optimizes_again_when_an_image_is_replaced
    add_image("assets/img/a.png")
    run_plugin
    add_image("assets/img/a.png", "a brand new photo")

    assert_equal ["a.png"], basenames(run_plugin.calls)
  end

  def test_reoptimizes_once_after_upgrading_from_the_old_cache_format
    add_image("assets/img/a.png")
    File.write(File.join(@source, "_compress_images_cache.yml"), { "assets/img/a.png" => "a.png" }.to_yaml)

    assert_equal ["a.png"], basenames(run_plugin.calls)
    assert_empty run_plugin.calls
  end

  def test_uses_site_source_and_config_instead_of_the_working_directory
    add_image("pics/b.jpg")
    add_image("assets/img/ignored.png")
    optimizer = Dir.chdir(Dir.tmpdir) do
      run_plugin(FakeOptimizer.new, "compress_images" => { "images_path" => "pics/*.jpg", "cache_file" => "_my_cache.yml" })
    end

    assert_equal ["b.jpg"], basenames(optimizer.calls)
    assert_equal ["pics/b.jpg"], cache("_my_cache.yml").keys
  end

  def test_a_broken_image_does_not_stop_the_others
    add_image("assets/img/good.png")
    add_image("assets/img/bad.png")
    optimizer = run_plugin(FakeOptimizer.new(fail_on: "bad.png"))

    assert_equal %w[bad.png good.png], basenames(optimizer.calls)
    assert_equal ["assets/img/good.png"], cache.keys
  end

  def test_does_not_rewrite_the_cache_when_nothing_changed
    add_image("assets/img/a.png")
    run_plugin
    cache_file = File.join(@source, "_compress_images_cache.yml")
    File.utime(Time.at(0), Time.at(0), cache_file)
    run_plugin

    assert_equal Time.at(0), File.mtime(cache_file)
  end

  def test_drops_deleted_images_from_the_cache
    add_image("assets/img/a.png")
    removed = add_image("assets/img/b.png")
    run_plugin
    File.delete(removed)
    run_plugin

    assert_equal ["assets/img/a.png"], cache.keys
  end

  def test_compresses_a_real_png
    image = add_image("assets/img/real.png", uncompressed_png)
    size_before = File.size(image)
    build

    assert_operator File.size(image), :<, size_before
    assert_equal ["assets/img/real.png"], cache.keys
  end

  def test_svgo_is_only_enabled_when_installed
    options = [false, true].map do |installed|
      s = site
      plugin = Jekyll::CompressImages.new(s.config)
      plugin.instance_variable_set(:@site, s)
      plugin.define_singleton_method(:executable?) { |_name| installed }
      plugin.send(:imageoptim_options)["svgo"]
    end

    assert_equal [false, true], options
  end

  def test_site_config_can_still_turn_svgo_on
    s = site("imageoptim" => { "svgo" => true })
    plugin = Jekyll::CompressImages.new(s.config)
    plugin.instance_variable_set(:@site, s)
    plugin.define_singleton_method(:executable?) { |_name| false }

    assert plugin.send(:imageoptim_options)["svgo"]
  end
end
