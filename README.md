# jekyll-compress-images

Plugin for compress/optimize images (jpg, png, gif, svg), using image_optim, image_optim_pack. 

# Installation

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

# Usage

on  `jekyll serve` or in `jekyll build` it will run compression, if you already run compression you don't need to worry because it will not run again on already compressed images which will save bunch of time! :)

**Enjoy 🎉
