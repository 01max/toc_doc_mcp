# frozen_string_literal: true

require "json"
require "rack/mock"

require_relative "../spec_helper"

RSpec.describe TocdocMcp::HttpApp do
  let(:token) { "valid-token-123" }
  let(:config) { TocdocMcp::Config.new(auth_token: token) }
  let(:gateway) { build(:fake_gateway) }
  let(:server) { TocdocMcp::Server.build(gateway: gateway) }
  let(:app) { described_class.new(config: config, server: server) }
  let(:request) { Rack::MockRequest.new(app) }

  def mcp_headers(auth_token = token)
    {
      "CONTENT_TYPE" => "application/json",
      "HTTP_ACCEPT" => "application/json, text/event-stream",
      "HTTP_AUTHORIZATION" => "Bearer #{auth_token}"
    }
  end

  def mcp_body(method: "tools/list", params: nil)
    payload = {
      jsonrpc: "2.0",
      id: 1,
      method: method
    }
    payload[:params] = params if params
    JSON.generate(payload)
  end

  def initialize_session
    body = mcp_body(
      method: "initialize",
      params: {
        protocolVersion: "2025-11-25",
        clientInfo: { name: "spec", version: "1" }
      }
    )
    response = request.post("/mcp", mcp_headers.merge(input: body))

    expect(response.status).to eq(200)
    response["Mcp-Session-Id"]
  end

  def authenticated_tools_list_response
    session_id = initialize_session
    request.post(
      "/mcp",
      mcp_headers.merge("HTTP_MCP_SESSION_ID" => session_id, input: mcp_body)
    )
  end

  def parse_mcp_response(response)
    body = response.body
    body = body.delete_prefix("data: ").strip if body.start_with?("data: ")
    JSON.parse(body)
  end

  it "routes authenticated MCP requests to the HTTP transport" do
    response = authenticated_tools_list_response

    expect(response.status).to eq(200)
    parsed = parse_mcp_response(response)
    names = parsed.fetch("result").fetch("tools").map { |tool| tool.fetch("name") }
    expect(names).to contain_exactly(
      "search_practitioners",
      "get_booking_context",
      "search_availabilities"
    )
  end

  it "does not expose mutating tools over HTTP" do
    response = authenticated_tools_list_response

    names = parse_mcp_response(response).fetch("result").fetch("tools").map { |tool| tool.fetch("name") }
    expect(names).not_to include(
      "book_appointment",
      "cancel_appointment",
      "login",
      "manage_account",
      "reserve_slot"
    )
  end

  it "rejects missing bearer tokens before MCP handling" do
    response = request.post("/mcp", mcp_headers.merge("HTTP_AUTHORIZATION" => nil, input: mcp_body))

    expect(response.status).to eq(401)
    expect(response["WWW-Authenticate"]).to eq('Bearer realm="tocdoc-mcp"')
    expect(response.body).not_to include(token)
  end

  it "rejects malformed bearer tokens before MCP handling" do
    response = request.post("/mcp", mcp_headers.merge("HTTP_AUTHORIZATION" => "Token #{token}", input: mcp_body))

    expect(response.status).to eq(401)
    expect(response.body).not_to include(token)
  end

  it "rejects invalid bearer tokens before MCP handling" do
    response = request.post("/mcp", mcp_headers("wrong-token").merge(input: mcp_body))

    expect(response.status).to eq(401)
    expect(response.body).not_to include("wrong-token")
  end

  it "serves health without authorization" do
    response = request.get("/health")

    expect(response.status).to eq(200)
    expect(JSON.parse(response.body)).to eq("status" => "ok", "mode" => "http")
  end

  it "keeps health response free of MCP and secret data" do
    response = request.get("/health")

    expect(response.body).not_to include("search_practitioners")
    expect(response.body).not_to include("tools")
    expect(response.body).not_to include(token)
    expect(response.body).not_to include("Authorization")
  end
end
