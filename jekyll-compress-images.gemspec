Gem::Specification.new do |s|
  s.name        = 'jekyll-compress-images'
  s.version     = '1.1'
  s.licenses    = ['MIT']
  s.summary     = "Jekyll plugin for compress/optimize images (jpg, png, gif, svg)"
  s.description = "Plugin for compress/optimize images (jpg, png, gif, svg). If you are struggle how to install more information you can find here: https://github.com/valerijaspasojevic/jekyll-compress-images"
  s.authors     = ["Valerija Spasojevic"]
  s.email       = 'spasojevic.valerija@gmail.com'
  s.files       = Dir.glob('lib/*')
  s.homepage    = 'https://rubygems.org/gems/jekyll-compress-images'
  s.metadata    = { "source_code_uri" => "https://github.com/valerijaspasojevic/jekyll-compress-images" }
  s.add_runtime_dependency 'image_optim', '>= 0'
  s.add_runtime_dependency 'image_optim_pack', '>= 0'
end
