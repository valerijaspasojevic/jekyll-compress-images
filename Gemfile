source "https://rubygems.org"

gemspec

# CI tests against older Jekyll too, e.g. JEKYLL_VERSION="~> 3.10"
if ENV["JEKYLL_VERSION"]
  gem "jekyll", ENV["JEKYLL_VERSION"]
  # Jekyll 3 sites need this for Markdown
  gem "kramdown-parser-gfm" if ENV["JEKYLL_VERSION"].include?("3.")
end
