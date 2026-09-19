[![Gem Version](https://badge.fury.io/rb/jekyll-compress-images.svg)](https://badge.fury.io/rb/jekyll-compress-images)
[![Test](https://github.com/valerijaspasojevic/jekyll-compress-images/actions/workflows/test.yml/badge.svg)](https://github.com/valerijaspasojevic/jekyll-compress-images/actions/workflows/test.yml)

# jekyll-compress-images

Plugin for compressing/optimizing images (jpg, png, gif, svg).

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
```

## image_optim options

You can pass [image_optim](https://github.com/toy/image_optim) options by using:

```yaml
imageoptim:
  pngout: false
  svgo: true
  verbose: false
```

SVG optimization uses [svgo](https://github.com/svg/svgo), which isn't bundled. Install it with `npm install -g svgo`, or set `svgo: false` to hide the warning.

# Usage

On `jekyll serve` or `jekyll build`, compression will run. If your images are already compressed, you don't need to worry, because it won't run again, which saves a bunch of time! :)

Good to know:

- Images are optimized **in place**, in your source folder. Commit them afterwards.
- Commit `_compress_images_cache.yml` too, so other machines (and CI) know which images are already done.
- If you replace an image with a new file, it will be optimized again automatically.

# Development

```sh
bundle install
bundle exec rake test
```

If this project helps you, you can give me a robot instead of coffee. :)

[![paypal](https://www.paypalobjects.com/en_US/i/btn/btn_donateCC_LG.gif)](https://www.paypal.me/ValerijaSpasojevic)

**Enjoy** 🎉
