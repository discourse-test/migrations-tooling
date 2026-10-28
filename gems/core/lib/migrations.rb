# frozen_string_literal: true

require "active_support"
require "active_support/core_ext"
require "discourse_disco_cli"
require "mini_progress"
require "zeitwerk"

module Migrations
  class NoSettingsFound < StandardError
  end

  # Each gem registers its `config/locales` directory so that `enable_i18n`
  # loads the union of all translations (and an isolated gem still sees its own).
  def self.locale_load_paths
    @locale_load_paths ||= []
  end

  def self.register_locale_path(dir)
    locale_load_paths << dir if locale_load_paths.exclude?(dir)
  end

  # Root of the `migrations-core` gem. Other gems expose their own root.
  def self.root_path
    @root_path ||= File.expand_path("..", __dir__)
  end

  class DiscourseNotFoundError < StandardError
    include DiscourseDisco::CLI::PresentableError
  end

  class << self
    # Root of the Discourse install the tooling runs in, set by the launcher.
    # Nil when the tooling runs on its own.
    attr_accessor :host_app_root
  end

  def self.host_app_root!
    host_app_root ||
      raise(DiscourseNotFoundError, "This needs a Discourse install. Run it inside Discourse.")
  end

  def self.loader
    @loader ||=
      begin
        loader = Zeitwerk::Loader.new
        loader.log! if ENV["DEBUG"]
        configure_inflections(loader)
        loader.push_dir(File.join(__dir__, "migrations"), namespace: Migrations)
        configure_collapses(loader)
        loader
      end
  end

  def self.configure_inflections(loader)
    loader.inflector.inflect(
      {
        "id" => "ID",
        "files_db" => "FilesDB",
        "intermediate_db" => "IntermediateDB",
        "mappings_db" => "MappingsDB",
      },
    )
  end

  # Collapse `common/` into the root `Migrations` namespace, matching the previous
  # flat layout (e.g. `common/enum.rb` => `Migrations::Enum`). Nested directories
  # such as `common/set_store/` keep contributing a namespace segment
  # (`Migrations::SetStore::*`).
  def self.configure_collapses(loader)
    loader.collapse(File.join(__dir__, "migrations", "common"))
  end

  def self.setup_loader
    loader.setup
  end

  def self.enable_i18n
    require "i18n"

    locale_load_paths.each { |dir| I18n.load_path += Dir[File.join(dir, "**", "migrations.*.yml")] }
    I18n.backend.load_translations

    # always use English for now
    I18n.default_locale = :en
    I18n.locale = :en
  end

  def self.apply_global_config
    Regexp.timeout = 2
  end
end

Migrations.register_locale_path(File.join(Migrations.root_path, "config", "locales"))
Migrations.setup_loader
