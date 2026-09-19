require "test_helper"

class VariantsTest < Minitest::Test
  include SiteHelpers

  BOTH = { "compress_images" => { "webp" => true, "avif" => true } }.freeze

  def test_real_build_creates_webp_and_avif
    skip "cwebp/avifenc not installed" unless tool?("cwebp") && tool?("avifenc")
    add_image("assets/img/real.png", uncompressed_png)
    build(BOTH)

    webp = File.binread(site_path("assets/img/real.png.webp"))
    avif = File.binread(site_path("assets/img/real.png.avif"))
    assert_equal "WEBP", webp[8, 4]
    assert_equal "ftypavif", avif[4, 8]
    assert_operator webp.bytesize, :<, File.size(site_path("assets/img/real.png"))
  end

  def test_real_rebuild_keeps_the_variants
    skip "cwebp not installed" unless tool?("cwebp")
    add_image("assets/img/real.png", uncompressed_png)
    build("compress_images" => { "webp" => true })
    build("compress_images" => { "webp" => true })

    assert File.file?(site_path("assets/img/real.png.webp"))
  end

  def test_works_with_keep_originals_mode
    skip "cwebp not installed" unless tool?("cwebp")
    image = add_image("assets/img/real.png", uncompressed_png)
    original = File.binread(image)
    build("compress_images" => { "webp" => true, "overwrite_originals" => false })

    assert_equal original, File.binread(image)
    assert File.file?(site_path("assets/img/real.png.webp"))
  end

  def test_only_converts_jpg_and_png
    add_image("assets/img/a.gif")
    add_image("assets/img/b.svg")
    converted = []
    run_plugin(FakeOptimizer.new, BOTH) do |plugin|
      plugin.define_singleton_method(:executable?) { |_name| true }
      plugin.define_singleton_method(:convert) { |path, format| converted << [path, format] }
    end

    assert_empty converted
  end

  def test_skips_a_variant_that_is_bigger_than_the_original
    add_image("assets/img/a.png")
    calls = 0
    big = lambda do |plugin|
      plugin.define_singleton_method(:executable?) { |_name| true }
      plugin.define_singleton_method(:convert_command) do |_format, _input, output|
        calls += 1
        ["ruby", "-e", "File.write(ARGV[0], 'x' * 10_000)", output]
      end
    end
    run_plugin(FakeOptimizer.new, "compress_images" => { "webp" => true }, &big)
    refute @last_site.static_files.any? { |f| f.url.end_with?(".webp") }

    run_plugin(FakeOptimizer.new, "compress_images" => { "webp" => true }, &big)
    assert_equal 1, calls, "should remember it's not worth it"
  end

  def test_missing_tool_is_skipped_with_a_warning
    add_image("assets/img/a.png")
    run_plugin(FakeOptimizer.new, BOTH) do |plugin|
      plugin.define_singleton_method(:executable?) { |_name| false }
    end

    refute @last_site.static_files.any? { |f| f.url =~ /\.(webp|avif)\z/ }
  end

  def test_a_failed_conversion_does_not_stop_the_build
    add_image("assets/img/a.png")
    run_plugin(FakeOptimizer.new, "compress_images" => { "webp" => true }) do |plugin|
      plugin.define_singleton_method(:executable?) { |_name| true }
      plugin.define_singleton_method(:convert_command) { |*_| ["ruby", "-e", "exit 1"] }
    end

    refute @last_site.static_files.any? { |f| f.url.end_with?(".webp") }
  end

  def test_images_in_the_site_root
    skip "cwebp not installed" unless tool?("cwebp")
    add_image("logo.png", uncompressed_png)
    build("compress_images" => { "images_path" => "*.png", "webp" => true })

    assert File.file?(site_path("logo.png.webp"))
  end
end
