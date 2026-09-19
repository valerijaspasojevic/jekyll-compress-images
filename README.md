[![Gem Version](https://badge.fury.io/rb/jekyll-compress-images.svg)](https://badge.fury.io/rb/jekyll-compress-images)
[![Test](https://github.com/valerijaspasojevic/jekyll-compress-images/actions/workflows/test.yml/badge.svg)](https://github.com/valerijaspasojevic/jekyll-compress-images/actions/workflows/test.yml)

# jekyll-compress-images

Plugin for compressing/optimizing images (jpg, png, gif, svg), and optionally creating WebP and AVIF versions.

# Installation

Add to your `Gemfile`:

```ruby
gem 'jekyll-compress-images'
```

and in `_config.yml`:

```yaml
plugins:
  - jekyll-compress-images
```

Run `bundle install` in your project folder.

# Configuration

If you want to set up a different path for images, open `_config.yml` and add:

```yaml
compress_images:
  images_path: "yourpath/img/**/*.{gif,png,jpg,jpeg,svg}"
```

If you don't configure it, the default path will be `assets/img/**/*.{gif,png,jpg,jpeg,svg}`.

All options with their defaults:

```yaml
compress_images:
  images_path: "assets/img/**/*.{gif,png,jpg,jpeg,svg}"  # relative to your site source
  cache_file: "_compress_images_cache.yml"               # remembers which images are already optimized
  threads: 8                                              # defaults to the number of CPU cores
  overwrite_originals: true                               # false = only the published images in _site are compressed
  webp: false                                             # create .webp versions of jpg/png images
  webp_quality: 80
  avif: false                                             # create .avif versions of jpg/png images
  avif_quality: 60
```

## Keep your original images

By default, images are compressed **in place**, in your source folder. If you'd rather keep high-quality originals in your repo and only publish compressed ones, set:

```yaml
compress_images:
  overwrite_originals: false
```

Compressed copies are kept in `.jekyll-cache/compress-images/`, so only the first build is slow. Your source images are never touched, and `_compress_images_cache.yml` isn't needed.

## WebP and AVIF

WebP and AVIF are usually much smaller than JPG/PNG. Turn them on with:

```yaml
compress_images:
  webp: true
  avif: true
```

This needs `cwebp` and `avifenc` (version 1.0 or newer) installed:

- macOS: `brew install webp libavif`
- Ubuntu 24.04+/Debian 12+ (and GitHub Actions `ubuntu-latest`): `sudo apt-get install webp libavif-bin`

For every jpg/png, a `.webp` and `.avif` file is added next to it in `_site`, e.g. `hero.jpg.webp`. If one comes out bigger than the original, it's skipped. Your source folder isn't touched.

Browsers only use these files if your HTML asks for them, so use the `picture` tag instead of `<img>`:

```liquid
{% picture assets/img/hero.jpg alt="Hero" class="cover" loading="lazy" %}
{% picture {{ page.image }} alt="{{ page.title }}" %}
```

which becomes:

```html
<picture>
  <source srcset="/assets/img/hero.jpg.avif" type="image/avif">
  <source srcset="/assets/img/hero.jpg.webp" type="image/webp">
  <img src="/assets/img/hero.jpg" alt="Hero" class="cover" loading="lazy">
</picture>
```

Anything after the image path is added to the `<img>`. Browsers that don't support AVIF/WebP use the original image. If you already use another plugin with a `picture` tag (like jekyll_picture_tag), that one is kept.

## image_optim options

You can pass [image_optim](https://github.com/toy/image_optim) options by using:

```yaml
imageoptim:
  pngout: false
  svgo: true
  verbose: false
```

SVG optimization uses [svgo](https://github.com/svg/svgo), which isn't bundled. It's used automatically when it's installed (`npm install -g svgo`).

# Usage

On `jekyll serve` or `jekyll build`, compression will run. If your images are already compressed, you don't need to worry, because it won't run again, which saves a bunch of time! :)

Good to know:

- Images are optimized **in place**, in your source folder (unless you set `overwrite_originals: false`). Commit them afterwards.
- Commit `_compress_images_cache.yml` too, so other machines (and CI) know which images are already done.
- Each build prints a summary like `Optimized 12 images, saved 3.4 MB`. Run with `--verbose` to see every image.
- If you replace an image with a new file, it will be optimized again automatically.

# Development

```sh
bundle install
bundle exec rake test
```

If this project helps you, you can give me a robot instead of coffee. :)

[![paypal](https://www.paypalobjects.com/en_US/i/btn/btn_donateCC_LG.gif)](https://www.paypal.me/ValerijaSpasojevic)

**Enjoy** 🎉
