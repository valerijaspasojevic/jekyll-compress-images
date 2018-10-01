[![Gem Version](https://badge.fury.io/rb/jekyll-compress-images.svg)](https://badge.fury.io/rb/jekyll-compress-images)

# jekyll-compress-images

Plugin for compress/optimize images (jpg, png, gif, svg).

# Installation

add to your `Gemfile`:

```ruby
gem 'jekyll-compress-images'
```

and in `_config.yml`:

```ruby
plugins:
  - jekyll-compress-images
```

Run `bundle install` in your project folder

# Configuration

If you want to setup different path for images, open `_config.yml` add

```ruby
compress_images:
  images_path: "yourpath/img/**/*.{gif,png,jpg,jpeg,svg}"
```

if you don't configure your default path will be `assets/img/**/*.{gif,png,jpg,jpeg,svg}`

## image_optim options

You can pass [image_optim](https://github.com/toy/image_optim) options by using

```ruby
imageoptim:
  pngout: false
  svgo: true
  verbose: false
```

# Usage

on  `jekyll serve` or in `jekyll build` you will run compression, if your images are already compressed, you don't need to worry because it will not run again which will save bunch of time! :)


If this project helps you, you can give me a robot instead of coffee. :)

[![paypal](https://www.paypalobjects.com/en_US/i/btn/btn_donateCC_LG.gif)](https://www.paypal.me/ValerijaSpasojevic)

**Enjoy** 🎉
