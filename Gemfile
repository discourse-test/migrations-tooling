# frozen_string_literal: true

source "https://rubygems.org"

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
