# frozen_string_literal: true

source "https://rubygems.org"

gem "migrations-core", path: "gems/core"
gem "migrations-tooling", path: "gems/tooling"
gem "migrations-converters", path: "gems/converters"
gem "migrations-importer", path: "gems/importer"

source "https://rubygems.pkg.github.com/discourse-test" do
  gem "discourse-disco-cli"
  gem "mini_progress"
end

group :test do
  gem "rspec"
end

# Discourse never loads this group, so a Discourse boot doesn't resolve or
# install these gems. They are only for working on the plugin on its own.
group :lint do
  gem "lefthook"
  gem "rubocop-discourse-base"
  gem "rubocop-rspec"
  gem "rubycritic"
  gem "syntax_tree"
end
