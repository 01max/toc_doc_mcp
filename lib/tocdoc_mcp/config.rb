# frozen_string_literal: true

module TocdocMcp
  class ConfigurationError < StandardError; end

  class Config
    PLACEHOLDER_TOKENS = [
      "change-me",
      "changeme",
      "secret",
      "your-secret-token",
      "replace-me",
      "replace-with-a-long-random-token"
    ].freeze

    attr_reader :host, :port, :auth_token

    def self.http_from_env(env = ENV)
      new(
        host: env.fetch("HOST", "0.0.0.0"),
        port: env.fetch("PORT", "8080"),
        auth_token: env["MCP_AUTH_TOKEN"],
        http_stateless: truthy?(env["MCP_HTTP_STATELESS"])
      ).tap(&:validate_http!)
    end

    def self.truthy?(value)
      %w[1 true yes on].include?(value.to_s.downcase)
    end

    def initialize(host: "0.0.0.0", port: 8080, auth_token: nil, http_stateless: false)
      @host = host.to_s
      @port = parse_port(port)
      @auth_token = auth_token
      @http_stateless = !!http_stateless
    end

    def http_stateless?
      @http_stateless
    end

    def validate_http!
      token = auth_token.to_s.strip

      if token.empty?
        raise ConfigurationError, "MCP_AUTH_TOKEN is required for HTTP mode"
      end

      if PLACEHOLDER_TOKENS.include?(token.downcase)
        raise ConfigurationError, "MCP_AUTH_TOKEN must not use a placeholder value"
      end

      true
    end

    private

    def parse_port(value)
      Integer(value).tap do |port|
        raise ConfigurationError, "PORT must be between 1 and 65535" unless (1..65_535).cover?(port)
      end
    rescue ArgumentError, TypeError
      raise ConfigurationError, "PORT must be an integer"
    end
  end
end
