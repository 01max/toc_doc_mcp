# frozen_string_literal: true

module TocdocMcp
  module Server
    module_function

    def build
      MCP::Server.new(
        name: "tocdoc_mcp",
        title: "TocDoc MCP",
        version: TocdocMcp::VERSION,
        tools: []
      )
    end
  end
end
