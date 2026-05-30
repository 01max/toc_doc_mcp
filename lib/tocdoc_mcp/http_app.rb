# frozen_string_literal: true

require "digest"
require "json"
require "rack"
require "rack/utils"

module TocdocMcp
  class HttpApp
    REALM = "tocdoc-mcp"

    def initialize(config: Config.http_from_env, server: TocdocMcp.server, transport: nil)
      config.validate_http!
      @config = config
      @transport = transport || MCP::Server::Transports::StreamableHTTPTransport.new(
        server,
        stateless: config.http_stateless?
      )
    end

    def call(env)
      request = Rack::Request.new(env)

      return health_response if request.get? && request.path_info == "/health"
      return handle_mcp(request) if request.path_info == "/mcp"

      json_response(404, error: "Not found")
    end

    private

    attr_reader :config, :transport

    def handle_mcp(request)
      return unauthorized_response unless authorized?(request.get_header("HTTP_AUTHORIZATION"))

      transport.handle_request(request)
    end

    def authorized?(header)
      match = header.to_s.match(/\ABearer\s+(.+)\z/)
      return false unless match

      expected = Digest::SHA256.hexdigest(config.auth_token.to_s)
      candidate = Digest::SHA256.hexdigest(match[1].strip)
      Rack::Utils.secure_compare(candidate, expected)
    end

    def health_response
      json_response(200, status: "ok", mode: "http")
    end

    def unauthorized_response
      json_response(
        401,
        { "WWW-Authenticate" => %(Bearer realm="#{REALM}") },
        error: "Unauthorized"
      )
    end

    def json_response(status, headers = {}, payload)
      body = JSON.generate(payload)
      [
        status,
        {
          "Content-Type" => "application/json",
          "Content-Length" => body.bytesize.to_s
        }.merge(headers),
        [body]
      ]
    end
  end
end
