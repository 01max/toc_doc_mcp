# frozen_string_literal: true

FactoryBot.define do
  factory :fake_gateway, class: "SpecSupport::FakeGateway" do
    responses { {} }

    initialize_with { new(responses: responses) }
  end
end
