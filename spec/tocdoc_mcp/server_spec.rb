# frozen_string_literal: true

require_relative "../spec_helper"

RSpec.describe TocdocMcp::Server do
  let(:gateway) { build(:fake_gateway) }
  let(:server) { described_class.build(gateway: gateway) }

  def rpc(method, params = nil)
    request = {
      jsonrpc: "2.0",
      id: 1,
      method: method
    }
    request[:params] = params if params

    server.handle(request)
  end

  def call_tool(name, arguments)
    rpc("tools/call", { name: name, arguments: arguments })
  end

  def structured_content(response)
    response.dig(:result, :structuredContent)
  end

  it "registers the bootstrap read-only tools" do
    response = rpc("tools/list")

    names = response.dig(:result, :tools).map { |tool| tool[:name] }
    expect(names).to contain_exactly(
      "search_practitioners",
      "get_booking_context",
      "search_availabilities"
    )
  end

  it "does not expose mutating tools" do
    response = rpc("tools/list")

    names = response.dig(:result, :tools).map { |tool| tool[:name] }
    expect(names).not_to include(
      "book_appointment",
      "cancel_appointment",
      "login",
      "manage_account",
      "reserve_slot"
    )
  end

  it "returns normalized structured content for practitioner search" do
    gateway.respond_with(
      :search_practitioners,
      { query: "dentiste", location: "Metz", candidates: [{ profile_ref: "dentiste/metz/example" }] }
    )

    response = call_tool("search_practitioners", { query: "dentiste", location: "Metz" })

    expect(response.dig(:result, :isError)).to be(false)
    expect(structured_content(response)).to include(
      "query" => "dentiste",
      "location" => "Metz",
      "candidates" => [{ "profile_ref" => "dentiste/metz/example" }]
    )
  end

  it "returns normalized structured content for booking context" do
    gateway.respond_with(
      :get_booking_context,
      { profile_ref: "profile-a", visit_motives: [{ id: 12, name: "Consultation" }], agendas: [] }
    )

    response = call_tool("get_booking_context", { profile_ref: "profile-a" })

    expect(response.dig(:result, :isError)).to be(false)
    expect(structured_content(response)).to include(
      "profile_ref" => "profile-a",
      "visit_motives" => [{ "id" => 12, "name" => "Consultation" }],
      "agendas" => []
    )
  end

  it "accepts numeric profile references returned by search" do
    gateway.respond_with(
      :get_booking_context,
      { profile_ref: "123", visit_motives: [], agendas: [] }
    )

    response = call_tool("get_booking_context", { profile_ref: 123 })

    expect(response.dig(:result, :isError)).to be(false)
    expect(gateway.calls).to include(
      [:get_booking_context, { profile_ref: 123, diagnostics: false }]
    )
  end

  it "returns normalized structured content for availability search" do
    gateway.respond_with(
      :search_availabilities,
      {
        profile_ref: "profile-a",
        visit_motive_id: "12",
        agenda_ids: ["34"],
        slots: [{ start_time: "2026-06-01T09:00:00+02:00" }]
      }
    )

    response = call_tool(
      "search_availabilities",
      { profile_ref: "profile-a", visit_motive_id: "12", agenda_ids: ["34"] }
    )

    expect(response.dig(:result, :isError)).to be(false)
    expect(structured_content(response)).to include(
      "profile_ref" => "profile-a",
      "slots" => [{ "start_time" => "2026-06-01T09:00:00+02:00" }]
    )
  end

  it "validates required inputs before calling the gateway" do
    response = call_tool("search_practitioners", {})

    expect(response.dig(:result, :isError)).to be(true)
    expect(response.dig(:result, :content, 0, :text)).to include("Missing required arguments: query")
    expect(gateway.calls).to be_empty
  end

  it "treats empty search results as successful responses" do
    gateway.respond_with(:search_practitioners, { query: "missing", candidates: [] })

    response = call_tool("search_practitioners", { query: "missing" })

    expect(response.dig(:result, :isError)).to be(false)
    expect(structured_content(response)).to include("candidates" => [])
  end

  it "treats empty availability as a successful response" do
    gateway.respond_with(
      :search_availabilities,
      { profile_ref: "profile-a", visit_motive_id: "12", agenda_ids: ["34"], slots: [] }
    )

    response = call_tool(
      "search_availabilities",
      { profile_ref: "profile-a", visit_motive_id: "12", agenda_ids: ["34"] }
    )

    expect(response.dig(:result, :isError)).to be(false)
    expect(structured_content(response)).to include("slots" => [])
  end

  it "normalizes application errors for MCP clients" do
    gateway.respond_with(:get_booking_context, TocdocMcp::NotFoundError.new)

    response = call_tool("get_booking_context", { profile_ref: "missing" })

    expect(response.dig(:result, :isError)).to be(true)
    expect(structured_content(response)).to eq(
      "error" => {
        "category" => "not_found",
        "message" => "Requested public resource was not found"
      }
    )
  end
end
