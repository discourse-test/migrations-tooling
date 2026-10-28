# frozen_string_literal: true

DiscourseDisco::CLI::Registry.register(
  name: "schema",
  command_class: "Migrations::Tooling::CLI::SchemaCommand",
  description: "Manage database schemas",
)

DiscourseDisco::CLI::Registry.register(
  name: "check",
  command_class: "Migrations::Tooling::CLI::CheckCommand",
  description: "Run all schema and converter checks",
)
