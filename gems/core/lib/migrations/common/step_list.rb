# frozen_string_literal: true

module Migrations
  # The `type:` of the `--only` and `--skip` options: turns a comma-separated
  # value into step names, normalized the way `ClassFilter` names steps.
  module StepList
    def self.call(value)
      value.to_s.split(",").map { |name| name.strip.demodulize.underscore }
    end
  end
end
