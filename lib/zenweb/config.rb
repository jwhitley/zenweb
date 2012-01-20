require "yaml"

gem "rake"
require "rake"

module Zenweb
  ##
  # Provides a hierarchical dictionary made of yaml fragments and files.
  #
  # Any given page in zenweb can start with a YAML header. All files
  # named "_config.yml" up the directory tree to the top are
  # considered parents of that config. Access a config like you would
  # any hash and you get inherited values.

  class Config
    include Rake::DSL

    ##
    # The shared site instance

    attr_reader :site

    ##
    # The path to this config's file

    attr_reader :path

    ##
    # The parent to this config or nil if we're at the top level _config.yml.

    attr_reader :parent

    ##
    # Create a new Config for site at a given path.

    def initialize site, path
      @site, @path, @parent = site, path, nil

      File.each_parent path, "_config.yml" do |config|
        next unless File.file? config
        @parent = site.configs[config] unless config == path
        break if @parent
      end

      @parent ||= Config::Null
    end

    ##
    # Access value at +k+. The value can be inherited from the parent configs.

    def [] k
      h[k] or parent[k]
    end

    def h # :nodoc:
      @h ||= YAML.load(File.read path) || {}
    end

    def inspect # :nodoc:
      if Rake.application.options.trace then
        "Config[#{path.inspect}, #{parent.inspect}, #{h.inspect[1..-2]}]"
      else
        "Config[#{path.inspect}, #{parent.inspect}]"
      end
    end

    def to_s # :nodoc:
      "Config[#{path.inspect}]"
    end

    ##
    # Wire up this config to the rest of the rake dependencies.

    def wire
      @wired ||= false # HACK
      return if @wired
      @wired = true

      file self.path

      file self.path => self.parent.path if self.parent.path # HACK

      self.parent.wire
    end
  end # class Config

  # :stopdoc:
  Config::Null = Class.new Config do
    def [] k;                    end
    def initialize;              end
    def inspect; "Config::Null"; end
    def wire;                    end
  end.new
  # :startdoc:
end
