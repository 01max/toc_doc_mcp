# frozen_string_literal: true

require "json"

module TocdocMcp
  module ToolResponse
    module_function

    def success(payload)
      MCP::Tool::Response.new(
        [{ type: "text", text: JSON.pretty_generate(payload) }],
        structured_content: stringify_keys(payload)
      )
    end

    def error(error)
      payload = {
        error: {
          category: error.category,
          message: error.message
        }
      }

      MCP::Tool::Response.new(
        [{ type: "text", text: JSON.pretty_generate(payload) }],
        error: true,
        structured_content: stringify_keys(payload)
      )
    end

    def stringify_keys(value)
      case value
      when Hash
        value.to_h { |key, child| [key.to_s, stringify_keys(child)] }
      when Array
        value.map { |child| stringify_keys(child) }
      else
        value
      end
    end
  end
end
