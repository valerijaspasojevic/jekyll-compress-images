require "minitest/autorun"
require "fileutils"
require "tmpdir"
require "zlib"
require "jekyll"
require "jekyll-compress-images"

Jekyll.logger.log_level = :error

# Pretends to optimize by appending a byte, and remembers what it was asked to do
class FakeOptimizer
  attr_reader :calls

  def initialize(fail_on: nil)
    @calls = []
    @fail_on = fail_on
    @mutex = Mutex.new
  end

  def optimize_image!(path)
    @mutex.synchronize { @calls << path }
    raise "broken image" if @fail_on && path.end_with?(@fail_on)

    File.open(path, "ab") { |f| f.write("\0") }
  end
end

module SiteHelpers
  def setup
    @source = Dir.mktmpdir("jekyll-compress-images")
  end

  def teardown
    FileUtils.rm_rf(@source)
  end

  def site(config = {})
    Jekyll::Site.new(Jekyll.configuration(config.merge(
      "source" => @source,
      "destination" => File.join(@source, "_site"),
      "quiet" => true
    )))
  end

  # Runs the plugin the way Jekyll does, but with a fake optimizer
  def run_plugin(optimizer = FakeOptimizer.new, config = {})
    s = site(config)
    s.reset
    s.read
    plugin = Jekyll::CompressImages.new(s.config)
    plugin.define_singleton_method(:image_optim) { optimizer }
    yield plugin if block_given?
    plugin.generate(s)
    @last_site = s
    optimizer
  end

  # A full `jekyll build` with the real plugin and real image_optim
  def build(config = {})
    s = site(config)
    s.process
    s
  end

  def add_file(path, content)
    full = File.join(@source, path)
    FileUtils.mkdir_p(File.dirname(full))
    File.binwrite(full, content)
    full
  end

  def add_image(path, content = "image-#{path}")
    add_file(path, content)
  end

  def source_path(path)
    File.join(@source, path)
  end

  def site_path(path)
    File.join(@source, "_site", path)
  end

  def cache(file = "_compress_images_cache.yml")
    YAML.safe_load(File.read(File.join(@source, file)))
  end

  def cache_dir_files
    Dir.glob(File.join(@source, ".jekyll-cache", "compress-images", "*")).map { |f| File.basename(f) }
  end

  def basenames(paths)
    paths.map { |p| File.basename(p) }.sort
  end

  # A photo-like 128x128 PNG (gradient plus noise) saved without zlib compression,
  # so there's always something to optimize and WebP/AVIF come out smaller
  def uncompressed_png
    random = Random.new(42)
    chunk = lambda do |type, data|
      [data.bytesize].pack("N") + type + data + [Zlib.crc32(type + data)].pack("N")
    end
    rows = Array.new(128) do |y|
      "\0" + Array.new(128) { |x| [x + random.rand(40), y + random.rand(40), 128 + random.rand(40)].pack("C3") }.join
    end.join
    "\x89PNG\r\n\x1a\n".b +
      chunk.call("IHDR", [128, 128, 8, 2, 0, 0, 0].pack("N2C5")) +
      chunk.call("IDAT", Zlib::Deflate.deflate(rows, Zlib::NO_COMPRESSION)) +
      chunk.call("IEND", "")
  end

  def tool?(name)
    ENV["PATH"].split(File::PATH_SEPARATOR).any? { |dir| File.executable?(File.join(dir, name)) }
  end
end
