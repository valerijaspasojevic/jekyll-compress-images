# jekyll-compress-images

Plugin for compress/optimize images (jpg, png, gif, svg), using image_optim, image_optim_pack. 

# Installation using gem

add to your `Gemfile`:

```ruby
gem 'image_optim'
gem 'image_optim_pack'
gem 'jekyll_compress_images'
```

and in `_config.yml`:

```ruby
plugins:
  - image_optim
  - image_optim_pack
  - jekyll_compress_images
```

# Installation in _plugins (you can skip this step if you already install it using gem)

add to your `Gemfile`:

```ruby
gem 'image_optim'
gem 'image_optim_pack'
```

and in `_config.yml`:

```ruby
plugins:
  - image_optim
  - image_optim_pack
```
Download from the repo `compress_images.rb`, put file in `_plugins` folder

# Configuration

If you want to setup different path for images, open `_config.yml` add

```ruby
compress_images:
  images_path: "yourpath/img/**/*.{gif,png,jpg,jpeg}"
```  

if you don't configure your default path will be `assets/img/**/*.{gif,png,jpg,jpeg}`

**Run `bundle install`

# Usage

on  `jekyll serve` or in `jekyll build` it will run compression, if you already run compression you don't need to worry because it will not run again on already compressed images which will save bunch of time! :)

**Enjoy 🎉
