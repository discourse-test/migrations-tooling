# frozen_string_literal: true

RSpec.describe Migrations::StepList do
  it "splits a comma-separated value into normalized step names" do
    expect(described_class.call("Users, topic_users,Migrations::Steps::TopicTags")).to eq(
      %w[users topic_users topic_tags],
    )
  end
end
