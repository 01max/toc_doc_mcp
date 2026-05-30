# frozen_string_literal: true

require "mcp"

require_relative "tocdoc_mcp/server"
require_relative "tocdoc_mcp/version"

module TocdocMcp
  class << self
    def server
      Server.build
    end

    def run_stdio
      MCP::Server::Transports::StdioTransport.new(server).open
    end
  end
end
