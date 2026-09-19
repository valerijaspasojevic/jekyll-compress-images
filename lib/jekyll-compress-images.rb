require "cgi"
require "digest"
require "etc"
require "fileutils"
require "open3"
require "pathname"
require "set"
require "yaml"
require "image_optim"
require "image_optim_pack"
require "in_threads"

module Jekyll
  class CompressImages < Generator
    safe true

    LOG_TOPIC = "CompressImages:".freeze

    DEFAULT_OPTIONS = {
      "cache_file"          => "_compress_images_cache.yml",
      "images_path"         => "assets/img/**/*.{gif,png,jpg,jpeg,svg}",
      "threads"             => Etc.nprocessors,
      "overwrite_originals" => true,
      "webp"                => false,
      "webp_quality"        => 80,
      "avif"                => false,
      "avif_quality"        => 60
    }.freeze

    DEFAULT_IMAGEOPTIM_OPTIONS = {
      "pngout"  => false,
      "verbose" => false
    }.freeze

    # Extra formats we can create, the tool that makes them and how to install it
    VARIANTS = {
      "webp" => { "tool" => "cwebp",   "install" => "brew install webp / apt install webp" },
      "avif" => { "tool" => "avifenc", "install" => "brew install libavif / apt install libavif-bin" }
    }.freeze

    # Formats cwebp and avifenc can read
    CONVERTIBLE = %w[.jpg .jpeg .png].freeze

    def generate(site)
      @site = site
      @config = DEFAULT_OPTIONS.merge(site.config["compress_images"] || {})
      @mutex = Mutex.new
      @stats = { "optimized" => 0, "saved" => 0, "created" => 0 }
      @used_cache_files = Set.new
      @digests = {}

      images = Dir.glob(File.expand_path(@config["images_path"], site.source)).select { |path| File.file?(path) }.sort

      # Look these up before optimize_copies points them at the cache folder
      files = published_files(images)

      if @config["overwrite_originals"]
        optimize_originals(images)
      else
        optimize_copies(files)
      end
      create_variants(files)
      clean_cache_dir
      log_summary
    end

    private

    # Optimizes images in the source folder and remembers them in the cache file
    def optimize_originals(images)
      @cache_path = File.expand_path(@config["cache_file"], site.source)
      @original_cache = load_cache
      # Only keep entries for images that still exist, so deleted images drop out of the cache
      @cache = @original_cache.select { |key, _| images.any? { |path| relative(path) == key } }

      pending = images.reject { |path| @cache[relative(path)] == digest(path) }
      in_parallel(pending) do |path|
        safely("optimize", path) do
          optimize(path)
          # Store the digest of the optimized file, so we only run again when the image is replaced
          new_digest = digest(path)
          @mutex.synchronize { @cache[relative(path)] = new_digest }
        end
      end
    ensure
      save_cache if @cache
    end

    # Leaves the originals untouched. Optimized copies live in the cache folder
    # and Jekyll publishes them instead of the originals.
    def optimize_copies(files)
      pending = files.keys.reject { |path| File.file?(cached_path(path, File.extname(path))) }
      pending = pending.uniq { |path| cached_path(path, File.extname(path)) }

      in_parallel(pending) do |path|
        safely("optimize", path) do
          write_atomically(cached_path(path, File.extname(path))) do |tmp|
            FileUtils.cp(path, tmp)
            optimize(tmp, path)
          end
        end
      end

      files.each do |path, file|
        copy = cached_path(path, File.extname(path))
        file.define_singleton_method(:path) { copy } if File.file?(copy)
      end
    end

    # Creates .webp/.avif files next to the images, e.g. hero.jpg -> hero.jpg.webp
    def create_variants(files)
      formats = VARIANTS.keys.select { |format| @config[format] && tool_installed?(format) }
      return if formats.empty?

      images = files.keys.select { |path| CONVERTIBLE.include?(File.extname(path).downcase) }
      jobs = images.product(formats)
      pending = jobs.reject { |path, format| File.file?(cached_path(path, ".#{format}")) || File.file?(skip_marker(path, format)) }
      pending = pending.uniq { |path, format| cached_path(path, ".#{format}") }

      in_parallel(pending) do |path, format|
        safely("create #{format} for", path) { convert(path, format) }
      end

      jobs.each do |path, format|
        variant = cached_path(path, ".#{format}")
        next unless File.file?(variant)

        file = StaticFile.new(site, site.source, File.dirname("/#{relative(path)}"), "#{File.basename(path)}.#{format}")
        file.define_singleton_method(:path) { variant }
        site.static_files << file
      end
    end

    def convert(path, format)
      target = cached_path(path, ".#{format}")
      write_atomically(target) do |tmp|
        output, status = Open3.capture2e(*convert_command(format, path, tmp))
        raise output.strip unless status.success?

        # Not worth publishing if it's bigger than the original, the picture tag then falls back to it
        if File.size(tmp) >= File.size(path)
          FileUtils.touch(skip_marker(path, format))
          FileUtils.rm_f(tmp)
        else
          Jekyll.logger.debug LOG_TOPIC, "Created #{relative(path)}.#{format}"
          @mutex.synchronize { @stats["created"] += 1 }
        end
      end
    end

    def convert_command(format, input, output)
      quality = @config["#{format}_quality"].to_s
      case format
      when "webp" then ["cwebp", "-quiet", "-q", quality, "-metadata", "icc", input, "-o", output]
      when "avif" then ["avifenc", "-q", quality, "-s", "6", "-j", "all", input, output]
      end
    end

    def optimize(path, original = path)
      size_before = File.size(path)
      image_optim.optimize_image!(path)
      saved = size_before - File.size(path)
      Jekyll.logger.debug LOG_TOPIC, "Optimized #{relative(original)} (-#{percent(saved, size_before)}%)"
      @mutex.synchronize do
        @stats["optimized"] += 1
        @stats["saved"] += saved
      end
    end

    def site
      @site
    end

    def image_optim
      @image_optim ||= ImageOptim.new(imageoptim_options)
    end

    # svgo isn't bundled, so only turn it on when it's installed (unless the site config says otherwise)
    def imageoptim_options
      DEFAULT_IMAGEOPTIM_OPTIONS.merge("svgo" => executable?("svgo") || ENV.key?("SVGO_BIN"))
                                .merge(site.config["imageoptim"] || {})
    end

    # Static files Jekyll will publish at their usual URL, by source path
    def published_files(images)
      by_path = images.to_h { |path| [path, nil] }
      site.static_files.each_with_object({}) do |file, found|
        path = File.expand_path(file.path)
        found[path] = file if by_path.key?(path) && file.url == "/#{relative(path)}"
      end
    end

    def in_parallel(items, &block)
      items.in_threads([@config["threads"].to_i, 1].max).each(&block)
    end

    def safely(action, path)
      yield
    rescue StandardError => e
      Jekyll.logger.warn LOG_TOPIC, "Could not #{action} #{relative(path)}: #{e.message}"
    end

    # Writes to a temporary file first, so an interrupted build never leaves a half-done file in the cache
    def write_atomically(target)
      FileUtils.mkdir_p(File.dirname(target))
      tmp = "#{target}.tmp#{File.extname(target)}"
      yield tmp
      File.rename(tmp, target) if File.file?(tmp)
    ensure
      FileUtils.rm_f(tmp) if tmp
    end

    def cache_dir
      @cache_dir ||= File.join(File.expand_path(site.config["cache_dir"] || ".jekyll-cache", site.source), "compress-images")
    end

    def cached_path(path, extension)
      @digests[path] ||= digest(path)
      File.join(cache_dir, "#{@digests[path]}#{extension}").tap { |file| @used_cache_files << file }
    end

    def skip_marker(path, format)
      "#{cached_path(path, ".#{format}")}.skip".tap { |file| @used_cache_files << file }
    end

    def clean_cache_dir
      return unless File.directory?(cache_dir)

      (Dir.glob(File.join(cache_dir, "*")).to_set - @used_cache_files).each { |file| FileUtils.rm_f(file) }
    end

    def tool_installed?(format)
      tool = VARIANTS[format]["tool"]
      return true if executable?(tool)

      Jekyll.logger.warn LOG_TOPIC, "#{format} is enabled but `#{tool}` isn't installed (#{VARIANTS[format]["install"]})"
      false
    end

    def executable?(name)
      ENV["PATH"].to_s.split(File::PATH_SEPARATOR).any? { |dir| File.executable?(File.join(dir, name)) }
    end

    def log_summary
      if @stats["optimized"].positive?
        Jekyll.logger.info LOG_TOPIC, "Optimized #{@stats["optimized"]} #{@stats["optimized"] == 1 ? "image" : "images"}, saved #{human_size(@stats["saved"])}"
      end
      return unless @stats["created"].positive?

      Jekyll.logger.info LOG_TOPIC, "Created #{@stats["created"]} WebP/AVIF #{@stats["created"] == 1 ? "file" : "files"}"
    end

    def human_size(bytes)
      return "#{bytes} B" if bytes < 1024
      return "#{(bytes / 1024.0).round(1)} KB" if bytes < 1024 * 1024

      "#{(bytes / 1024.0 / 1024).round(1)} MB"
    end

    def percent(part, whole)
      whole.zero? ? 0 : (part * 100.0 / whole).round(1)
    end

    def digest(path)
      Digest::SHA256.file(path).hexdigest
    end

    def relative(path)
      Pathname.new(path).relative_path_from(Pathname.new(site.source)).to_s
    end

    def load_cache
      return {} unless File.file?(@cache_path)

      cache = YAML.safe_load(File.read(@cache_path))
      cache.is_a?(Hash) ? cache : {}
    rescue Psych::Exception
      {}
    end

    # Only write when something changed, so `jekyll serve` doesn't pick up
    # a modified file and rebuild again
    def save_cache
      return if @cache == @original_cache

      File.write(@cache_path, @cache.sort.to_h.to_yaml)
    end
  end

  # {% picture assets/img/hero.jpg alt="Hero" class="cover" %}
  # Uses the AVIF/WebP versions when they exist, and falls back to the original image
  class CompressImagesPictureTag < Liquid::Tag
    def initialize(tag_name, markup, tokens)
      super
      @markup = markup
    end

    def render(context)
      site = context.registers[:site]
      src, attributes = Liquid::Template.parse(@markup).render(context).strip.split(/\s+/, 2)
      raise ArgumentError, "{% picture %} needs an image path, e.g. {% picture assets/img/hero.jpg alt=\"Hero\" %}" if src.to_s.empty?

      url = "/#{src.sub(%r!\A/+!, "")}"
      published = context.registers[:compress_images_urls] ||= site.static_files.map(&:url).to_set
      sources = %w[avif webp].select { |format| published.include?("#{url}.#{format}") }.map do |format|
        %(<source srcset="#{html_url(site, "#{url}.#{format}")}" type="image/#{format}">)
      end
      img = %(<img src="#{html_url(site, url)}"#{" #{attributes}" if attributes}>)

      sources.empty? ? img : "<picture>#{sources.join}#{img}</picture>"
    end

    private

    def html_url(site, url)
      CGI.escapeHTML("#{site.config["baseurl"].to_s.chomp("/")}#{url}".gsub(" ", "%20"))
    end
  end
end

# Don't take over the tag if another plugin (like jekyll_picture_tag) already registered it
Liquid::Template.register_tag("picture", Jekyll::CompressImagesPictureTag) unless Liquid::Template.tags["picture"]
