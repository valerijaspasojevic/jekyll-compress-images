# Changelog

## 1.4

- **New:** `overwrite_originals: false` keeps your source images untouched and only publishes compressed copies (#3).
- **New:** optional WebP and AVIF versions (`webp: true`, `avif: true`), using `cwebp` and `avifenc`.
- **New:** `{% picture %}` tag that uses the AVIF/WebP versions and falls back to the original image.
- **New:** one summary line per build, e.g. `Optimized 12 images, saved 3.4 MB`. Use `--verbose` to see every image.
- **Changed:** SVGs are only optimized when `svgo` is installed, so there's no more `svgo not found` warning (#4). You can still set `imageoptim: svgo: true`.
- Tested on Jekyll 3.10 and 4.x. Publishing a new version now requires two-factor login on RubyGems.

## 1.3

- **Fixed:** replaced images are now optimized again. Before, an image was skipped forever once its path was in the cache, even if you swapped in a new file.
- **Fixed:** settings are read from Jekyll's config, so `--config` with multiple files and `--source` work. Paths are now relative to the site source instead of the current directory.
- **Fixed:** one broken image no longer stops the whole build. It's logged as a warning and the other images are still optimized and cached.
- **Fixed:** the cache file is only written when something changed, so `jekyll serve` isn't triggered to rebuild again.
- **New:** images are optimized in parallel (configurable with `compress_images.threads`).
- **New:** log output shows how much each image shrank and respects `--quiet`.
- **New:** deleted images are removed from the cache.
- **Upgrade note:** the cache now stores a hash of each optimized file. After upgrading, every image is checked once more; already optimized images barely change.

## 1.2

- Added `imageoptim` options.
