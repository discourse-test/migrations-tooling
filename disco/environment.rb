# frozen_string_literal: true

module MigrationsTooling
  PLUGIN_ROOT = File.expand_path("..", __dir__)

  # The Discourse install the plugin sits in (`<root>/plugins/<plugin>`), or nil
  # when it runs on its own. `DISCO_STANDALONE=1` forces standalone.
  def self.discourse_root
    return if ENV["DISCO_STANDALONE"] == "1"

    plugins_dir = File.dirname(PLUGIN_ROOT)
    return if File.basename(plugins_dir) != "plugins"

    root = File.dirname(plugins_dir)
    root if File.exist?(File.join(root, "config", "application.rb"))
  end
end
