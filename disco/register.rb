# frozen_string_literal: true

require "discourse_disco_cli"

# The gems load when the first command class is looked up, so registering the
# commands stays cheap.
Object.autoload(:Migrations, File.expand_path("migrations.rb", __dir__))

DiscourseDisco::CLI::Registry.register(
  name: "check",
  command_class: "Migrations::Tooling::CLI::CheckCommand",
  description: "Run all schema and converter checks",
)

DiscourseDisco::CLI::Registry.register(
  name: "convert",
  command_class: "Migrations::Converters::CLI::ConvertCommand",
  description: "Convert a source dump into the IntermediateDB",
)

DiscourseDisco::CLI::Registry.register(
  name: "import",
  command_class: "Migrations::Importer::CLI::ImportCommand",
  description: "Import the IntermediateDB into a Discourse database",
)

DiscourseDisco::CLI::Registry.register(
  name: "schema",
  command_class: "Migrations::Tooling::CLI::SchemaCommand",
  description: "Manage database schemas",
)

DiscourseDisco::CLI::Registry.register(
  name: "upload",
  command_class: "Migrations::Importer::CLI::UploadCommand",
  description: "Import media uploads referenced by the IntermediateDB",
)
