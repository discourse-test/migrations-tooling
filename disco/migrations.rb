# frozen_string_literal: true

require_relative "environment"

require "migrations-core"
require "migrations-tooling"
require "migrations-converters"
require "migrations-importer"

Migrations.host_app_root = MigrationsTooling.discourse_root
Migrations.enable_i18n
Migrations.apply_global_config
