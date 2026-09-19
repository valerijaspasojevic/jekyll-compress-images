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
    @mutex.synchronize { @calls << File.basename(path) }
    raise "broken image" if @fail_on && path.end_with?(@fail_on)

    File.open(path, "ab") { |f| f.write("\0") }
  end
end

class TestCompressImages < Jekyll::CompressImages
  def initialize(optimizer)
    super({})
    @optimizer = optimizer
  end

  private

  def image_optim
    @optimizer
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

  def add_image(path, content = "image-#{path}")
    full = File.join(@source, path)
    FileUtils.mkdir_p(File.dirname(full))
    File.binwrite(full, content)
    full
  end

  def cache(file = "_compress_images_cache.yml")
    YAML.safe_load(File.read(File.join(@source, file)))
  end

  # A 64x64 PNG saved without any zlib compression, so there's always something to optimize
  def uncompressed_png
    chunk = lambda do |type, data|
      [data.bytesize].pack("N") + type + data + [Zlib.crc32(type + data)].pack("N")
    end
    rows = Array.new(64) { |y| "\0" + Array.new(64) { |x| [x * 4, y * 4, 128].pack("C3") }.join }.join
    "\x89PNG\r\n\x1a\n".b +
      chunk.call("IHDR", [64, 64, 8, 2, 0, 0, 0].pack("N2C5")) +
      chunk.call("IDAT", Zlib::Deflate.deflate(rows, Zlib::NO_COMPRESSION)) +
      chunk.call("IEND", "")
  end
end
