Gem::Specification.new do |s|
  s.name        = 'jekyll-compress-images'
  s.version     = '1.3'
  s.licenses    = ['MIT']
  s.summary     = "Jekyll plugin for compress/optimize images (jpg, png, gif, svg)"
  s.description = "Plugin for compressing/optimizing images (jpg, png, gif, svg). If you're struggling with installation, you can find more information here: https://github.com/valerijaspasojevic/jekyll-compress-images"
  s.authors     = ["Valerija Spasojevic"]
  s.email       = 'spasojevic.valerija@gmail.com'
  s.files       = Dir.glob('lib/*') + ['LICENSE', 'README.md']
  s.homepage    = 'https://github.com/valerijaspasojevic/jekyll-compress-images'
  s.metadata    = {
    "source_code_uri" => "https://github.com/valerijaspasojevic/jekyll-compress-images",
    "changelog_uri"   => "https://github.com/valerijaspasojevic/jekyll-compress-images/blob/master/CHANGELOG.md"
  }
  s.required_ruby_version = '>= 2.7'

  s.add_runtime_dependency 'jekyll', '>= 3.8', '< 5'
  s.add_runtime_dependency 'image_optim', '~> 0.31'
  s.add_runtime_dependency 'image_optim_pack', '~> 0.10'
  s.add_runtime_dependency 'in_threads', '~> 1.5'

  s.add_development_dependency 'minitest', '~> 5.0'
  s.add_development_dependency 'rake', '~> 13.0'
end
