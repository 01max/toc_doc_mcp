# frozen_string_literal: true

require "mcp"

require_relative "tocdoc_mcp/errors"
require_relative "tocdoc_mcp/gateway"
require_relative "tocdoc_mcp/normalizer"
require_relative "tocdoc_mcp/server"
require_relative "tocdoc_mcp/tools"
require_relative "tocdoc_mcp/version"

module TocdocMcp
  class << self
    def server(gateway: Gateway.new)
      Server.build(gateway: gateway)
    end

    def run_stdio
      MCP::Server::Transports::StdioTransport.new(server).open
    end
  end
end
