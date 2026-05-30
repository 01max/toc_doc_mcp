# frozen_string_literal: true

require_relative "../spec_helper"

RSpec.describe TocdocMcp::Gateway do
  subject(:gateway) { described_class.new }

  before do
    stub_const("TocDoc::Search", class_double("TocDoc::Search"))
    stub_const("TocDoc::BookingInfo", class_double("TocDoc::BookingInfo"))
    stub_const("TocDoc::Availability", class_double("TocDoc::Availability"))
  end

  it "combines query and location as a search hint" do
    profile = build(:toc_doc_profile)
    allow(TocDoc::Search).to receive(:where).and_return([profile])

    result = gateway.search_practitioners(query: "dentiste", location: "Metz")

    expect(TocDoc::Search).to have_received(:where).with(query: "dentiste Metz", type: "profile")
    expect(result[:candidates]).to eq([
      {
        profile_ref: 123,
        display_name: "Dr Example",
        kind: "practitioner",
        labels: [],
        location: "1 Rue Exemple, Metz"
      }
    ])
  end

  it "normalizes booking context identifiers" do
    allow(TocDoc::BookingInfo).to receive(:find).and_return(
      build(:toc_doc_booking_info)
    )

    result = gateway.get_booking_context(profile_ref: "profile-a")

    expect(TocDoc::BookingInfo).to have_received(:find).with("profile-a")
    expect(result[:visit_motives]).to eq([{ id: 2, name: "Consultation" }])
    expect(result[:agendas]).to eq([{ id: 3, practice_id: "practice-4", visit_motive_ids: [2] }])
  end

  it "normalizes availability slots" do
    slot = DateTime.parse("2026-06-01T09:00:00+02:00")
    allow(TocDoc::Availability).to receive(:where).and_return(
      build(:toc_doc_availability_collection, slot_values: [slot])
    )

    result = gateway.search_availabilities(
      profile_ref: "dentiste/metz/example",
      visit_motive_id: "2",
      agenda_ids: ["3"],
      practice_ids: ["practice-4"],
      start_date: "2026-06-01",
      telehealth: false
    )

    expect(TocDoc::Availability).to have_received(:where).with(
      visit_motive_ids: "2",
      agenda_ids: ["3"],
      start_date: Date.parse("2026-06-01"),
      limit: 10,
      practice_ids: ["practice-4"],
      telehealth: false,
      booking_slug: "dentiste/metz/example"
    )
    expect(result[:slots]).to eq([
      {
        start_time: "2026-06-01T09:00:00+02:00",
        visit_motive_id: "2",
        agenda_ids: ["3"],
        practice_ids: ["practice-4"],
        telehealth: false
      }
    ])
  end

  it "rejects invalid input before calling toc_doc" do
    allow(TocDoc::Availability).to receive(:where)

    expect { gateway.search_availabilities(profile_ref: "", visit_motive_id: "2", agenda_ids: ["3"]) }
      .to raise_error(TocdocMcp::ValidationError, "profile_ref is required")
    expect(TocDoc::Availability).not_to have_received(:where)
  end

  it "normalizes toc_doc not found errors" do
    allow(TocDoc::BookingInfo).to receive(:find).and_raise(TocDoc::NotFound.new(status: 404))

    expect { gateway.get_booking_context(profile_ref: "missing") }
      .to raise_error(TocdocMcp::NotFoundError)
  end

  it "normalizes toc_doc upstream errors without leaking raw bodies" do
    allow(TocDoc::Search).to receive(:where).and_raise(TocDoc::ServerError.new(status: 500, body: "raw upstream body"))

    expect { gateway.search_practitioners(query: "dentiste") }
      .to raise_error(TocdocMcp::UpstreamError, "Upstream public source failed")
  end
end
