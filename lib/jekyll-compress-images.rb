require "image_optim"
require "image_optim_pack"
require 'yaml'

module Jekyll
  class CompressImages < Generator
    safe true

    def generate(site)

      config = YAML::load_file "_config.yml"

      config = config["compress_images"] || {}

      @config = default_options.merge! config

      @image_optim = ImageOptim.new pngout: false, svgo: true, verbose: false

      @last_update = YAML::load_file @config["cache_file"] if File.file? @config["cache_file"]
      @last_update ||= {}

      Dir.glob(@config["images_path"]) { |image| analyze image }

      File.open(@config["cache_file"], "w") { |file| file.write @last_update.to_yaml }
    end

    def default_options
      {
        "cache_file" => "_compress_images_cache.yml",
        "images_path" => "assets/img/**/*.{gif,png,jpg,jpeg,svg}",
      }
    end

    def analyze(image)
      if @last_update.has_key? image
        optimize image if @last_update[image] != File.basename(image)
      else
        optimize image
      end
    end

    def optimize(image)
      puts "Optimizing #{image}".green
      @image_optim.optimize_image! image
      @last_update[image] = File.basename image
    end
  end
end
