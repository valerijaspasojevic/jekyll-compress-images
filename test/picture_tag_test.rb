require "test_helper"

class PictureTagTest < Minitest::Test
  include SiteHelpers

  def render_page(content, config = {})
    add_file("index.html", "---\n---\n#{content}")
    build(config)
    File.read(site_path("index.html")).strip
  end

  def test_uses_avif_and_webp_when_they_exist
    skip "cwebp/avifenc not installed" unless tool?("cwebp") && tool?("avifenc")
    add_image("assets/img/hero.png", uncompressed_png)
    html = render_page(%({% picture assets/img/hero.png alt="Hero" loading="lazy" %}),
                       "compress_images" => { "webp" => true, "avif" => true })

    assert_equal '<picture><source srcset="/assets/img/hero.png.avif" type="image/avif">' \
                 '<source srcset="/assets/img/hero.png.webp" type="image/webp">' \
                 '<img src="/assets/img/hero.png" alt="Hero" loading="lazy"></picture>', html
  end

  def test_falls_back_to_a_plain_img
    add_image("assets/img/hero.png", uncompressed_png)

    assert_equal '<img src="/assets/img/hero.png" alt="Hero">', render_page(%({% picture /assets/img/hero.png alt="Hero" %}))
  end

  def test_supports_liquid_variables_and_baseurl
    add_image("assets/img/hero.png", uncompressed_png)
    html = render_page(%({% assign img = "assets/img/hero.png" %}{% picture {{ img }} %}), "baseurl" => "/blog")

    assert_equal '<img src="/blog/assets/img/hero.png">', html
  end

  def test_works_inside_markdown
    skip "cwebp not installed" unless tool?("cwebp")
    add_image("assets/img/hero.png", uncompressed_png)
    add_file("post.md", "---\n---\nSome text\n\n{% picture assets/img/hero.png alt=\"Hero\" %}\n")
    build("compress_images" => { "webp" => true })

    assert_includes File.read(site_path("post.html")), '<picture><source srcset="/assets/img/hero.png.webp" type="image/webp"'
  end
end
