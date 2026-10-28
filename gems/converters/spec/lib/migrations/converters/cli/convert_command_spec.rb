# frozen_string_literal: true

RSpec.describe Migrations::Converters::CLI::ConvertCommand do
  describe "#call" do
    it "refuses a converter that needs Discourse when the tooling runs on its own" do
      allow(Migrations).to receive(:host_app_root).and_return(nil)

      expect { described_class.new(["discourse"]).call }.to raise_error(
        described_class::Error,
        "The discourse converter needs a Discourse install. Run it inside Discourse.",
      )
    end

    it "reports an unknown converter with the valid names" do
      expect { described_class.new(["unknown"]).call }.to raise_error(
        described_class::Error,
        /Unknown converter name: unknown\nValid names are: .*discourse/,
      )
    end
  end
end
