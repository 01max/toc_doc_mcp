# frozen_string_literal: true

module TocdocMcp
  module Server
    module_function

    def build(gateway: Gateway.new)
      server = MCP::Server.new(
        name: "tocdoc_mcp",
        version: TocdocMcp::VERSION,
        tools: []
      )

      Tools.register(server, gateway: gateway)
    end
  end
end
