# frozen_string_literal: true

FactoryBot.define do
  factory :toc_doc_profile, class: "SpecSupport::FakeProfile" do
    data do
      {
        "id" => 123,
        "name_with_title" => "Dr Example",
        "places" => [{ "city" => "Metz", "full_address" => "1 Rue Exemple, Metz" }]
      }
    end

    initialize_with { new(data: data) }
  end

  factory :toc_doc_booking_info, class: "SpecSupport::FakeBookingInfo" do
    payload do
      {
        "profile" => { "id" => 123, "name" => "Dr Example" },
        "specialities" => [{ "id" => 1, "name" => "Dentiste" }],
        "visit_motives" => [{ "id" => 2, "name" => "Consultation" }],
        "agendas" => [{ "id" => 3, "practice_id" => "practice-4", "visit_motive_ids" => [2] }],
        "places" => [{ "id" => "practice-4", "city" => "Metz" }],
        "practitioners" => [{ "id" => 123, "name" => "Dr Example" }]
      }
    end

    initialize_with { new(payload: payload) }
  end

  factory :toc_doc_availability_collection, class: "SpecSupport::FakeAvailabilityCollection" do
    slot_values { [DateTime.parse("2026-06-01T09:00:00+02:00")] }

    initialize_with { new(slot_values: slot_values) }
  end
end
