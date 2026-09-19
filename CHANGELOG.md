# Changelog

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
