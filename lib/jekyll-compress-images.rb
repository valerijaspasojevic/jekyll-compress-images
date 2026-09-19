require "digest"
require "etc"
require "pathname"
require "yaml"
require "image_optim"
require "image_optim_pack"
require "in_threads"

module Jekyll
  class CompressImages < Generator
    safe true

    LOG_TOPIC = "CompressImages:".freeze

    DEFAULT_OPTIONS = {
      "cache_file"  => "_compress_images_cache.yml",
      "images_path" => "assets/img/**/*.{gif,png,jpg,jpeg,svg}",
      "threads"     => Etc.nprocessors
    }.freeze

    DEFAULT_IMAGEOPTIM_OPTIONS = {
      "pngout"  => false,
      "svgo"    => true,
      "verbose" => false
    }.freeze

    def generate(site)
      @site = site
      @config = DEFAULT_OPTIONS.merge(site.config["compress_images"] || {})
      @cache_path = File.expand_path(@config["cache_file"], site.source)

      images = Dir.glob(File.expand_path(@config["images_path"], site.source)).select { |path| File.file?(path) }.sort
      @original_cache = load_cache
      # Only keep entries for images that still exist, so deleted images drop out of the cache
      @cache = @original_cache.select { |key, _| images.any? { |path| relative(path) == key } }
      @mutex = Mutex.new

      pending = images.reject { |path| @cache[relative(path)] == digest(path) }
      pending.in_threads([@config["threads"].to_i, 1].max).each { |path| optimize(path) } if pending.any?
    ensure
      save_cache if @cache
    end

    private

    def image_optim
      @image_optim ||= ImageOptim.new(DEFAULT_IMAGEOPTIM_OPTIONS.merge(@site.config["imageoptim"] || {}))
    end

    def optimize(path)
      size_before = File.size(path)
      image_optim.optimize_image!(path)
      size_after = File.size(path)
      saved = size_before.zero? ? 0 : ((size_before - size_after) * 100.0 / size_before).round(1)
      Jekyll.logger.info LOG_TOPIC, "Optimized #{relative(path)} (-#{saved}%)"

      # Store the digest of the optimized file, so we only run again when the image is replaced
      new_digest = digest(path)
      @mutex.synchronize { @cache[relative(path)] = new_digest }
    rescue StandardError => e
      Jekyll.logger.warn LOG_TOPIC, "Could not optimize #{relative(path)}: #{e.message}"
    end

    def digest(path)
      Digest::SHA256.file(path).hexdigest
    end

    def relative(path)
      Pathname.new(path).relative_path_from(Pathname.new(@site.source)).to_s
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
end
