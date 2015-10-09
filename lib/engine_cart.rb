require "engine_cart/version"
require 'engine_cart/gemfile_stanza'
require 'bundler'

module EngineCart
  require "engine_cart/engine" if defined? Rails

  class << self

    ##
    # Name of the engine we're testing
    attr_accessor :engine_name

    ##
    # Destination to generate the test app into
    attr_accessor :destination

    ##
    # Path to a Rails application template
    attr_accessor :template

    ##
    # Path to test app templates to make available to
    # the test app generator
    attr_accessor :templates_path


    ##
    # Additional options when generating a test rails application
    attr_accessor :rails_options

  end

  self.engine_name = ENV["CURRENT_ENGINE_NAME"]
  self.destination = ENV['ENGINE_CART_DESTINATION'] || ENV['RAILS_ROOT'] || "./spec/internal"
  self.template = ENV["ENGINE_CART_TEMPLATE"]
  self.templates_path = ENV['ENGINE_CART_TEMPLATES_PATH'] || "./spec/test_app_templates"
  self.rails_options = ENV['ENGINE_CART_RAILS_OPTIONS']

  def self.current_engine_name
    engine_name || File.basename(Dir.glob("*.gemspec").first, '.gemspec')
  end

  def self.load_application! path = nil
    require File.expand_path("config/environment", path || EngineCart.destination)
  end

  def self.within_test_app
    Dir.chdir(EngineCart.destination) do
      Bundler.with_clean_env do
        yield
      end
    end
  end

  def self.fingerprint
    @fingerprint || (@fingerprint_proc || method(:default_fingerprint)).call
  end
  
  def self.fingerprint= fingerprint
    @fingerprint = fingerprint
  end
  
  def self.fingerprint_proc= fingerprint_proc
    @fingerprint_proc = fingerprint_proc
  end

  def self.rails_fingerprint_proc extra_files = []
    lambda do
      EngineCart.default_fingerprint + (Dir.glob("./db/migrate/*") + Dir.glob("./lib/generators/**/**") + Dir.glob("./spec/test_app_templates/**/**") + extra_files).map {|f| File.mtime(f) }.max.to_s
    end
  end

  def self.default_fingerprint
    EngineCart.env_fingerprint + (Dir.glob("./*.gemspec") + [Bundler.default_gemfile.to_s, Bundler.default_lockfile.to_s]).map {|f| File.mtime(f) }.max.to_s
  end

  def self.env_fingerprint
    { 'RUBY_DESCRIPTION' => RUBY_DESCRIPTION, 'BUNDLE_GEMFILE' => Bundler.default_gemfile.to_s }.reject { |k, v| v.nil? || v.empty? }.to_s
  end

  def self.check_for_gemfile_stanza
    return unless File.exist? 'Gemfile'

    unless File.readlines('Gemfile').grep(/#{EngineCart.gemfile_stanza_check_line}/).any?
      Bundler.ui.warn "[EngineCart] For better results, consider updating the EngineCart stanza in your Gemfile with:\n\n"
      Bundler.ui.warn EngineCart.gemfile_stanza_text
    end
  end
end
