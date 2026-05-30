# frozen_string_literal: true

require_relative "../spec_helper"

RSpec.describe TocdocMcp::Config do
  it "loads HTTP configuration from environment values" do
    config = described_class.http_from_env(
      "HOST" => "127.0.0.1",
      "PORT" => "9292",
      "MCP_AUTH_TOKEN" => "valid-token-123",
      "MCP_HTTP_STATELESS" => "true"
    )

    expect(config.host).to eq("127.0.0.1")
    expect(config.port).to eq(9292)
    expect(config.auth_token).to eq("valid-token-123")
    expect(config).to be_http_stateless
  end

  it "rejects missing HTTP auth tokens" do
    expect { described_class.http_from_env({}) }
      .to raise_error(TocdocMcp::ConfigurationError, "MCP_AUTH_TOKEN is required for HTTP mode")
  end

  it "rejects blank HTTP auth tokens" do
    expect { described_class.http_from_env("MCP_AUTH_TOKEN" => " ") }
      .to raise_error(TocdocMcp::ConfigurationError, "MCP_AUTH_TOKEN is required for HTTP mode")
  end

  it "rejects placeholder HTTP auth tokens" do
    expect { described_class.http_from_env("MCP_AUTH_TOKEN" => "change-me") }
      .to raise_error(TocdocMcp::ConfigurationError, "MCP_AUTH_TOKEN must not use a placeholder value")
  end

  it "rejects invalid ports" do
    expect { described_class.http_from_env("MCP_AUTH_TOKEN" => "valid-token-123", "PORT" => "not-a-port") }
      .to raise_error(TocdocMcp::ConfigurationError, "PORT must be an integer")
  end
end
