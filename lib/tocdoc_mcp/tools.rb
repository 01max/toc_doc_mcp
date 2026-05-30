# frozen_string_literal: true

require_relative "errors"
require_relative "tool_response"

module TocdocMcp
  module Tools
    READ_ONLY_TOOL_NAMES = %w[
      search_practitioners
      get_booking_context
      search_availabilities
    ].freeze

    module_function

    def register(server, gateway:)
      register_search_practitioners(server, gateway)
      register_get_booking_context(server, gateway)
      register_search_availabilities(server, gateway)
      server
    end

    def register_search_practitioners(server, gateway)
      server.define_tool(
        name: "search_practitioners",
        description: "Search public profile candidates by partial practitioner, organization, or profile name. Broad specialty-and-city discovery is not reliable with the upstream autocomplete endpoint; location is only an optional search hint, not a filter.",
        input_schema: {
          type: "object",
          required: ["query"],
          properties: {
            query: {
              type: "string",
              description: "Partial practitioner, organization, or profile name. Vague specialty-only queries may return empty or irrelevant results."
            },
            location: {
              type: "string",
              description: "Optional search hint appended to the upstream query. This is not a reliable city, postcode, radius, or geographic filter."
            },
            limit: { type: "integer", minimum: 1 },
            diagnostics: { type: "boolean" }
          },
          additionalProperties: false
        }
      ) do |query:, location: nil, limit: 10, diagnostics: false|
        TocdocMcp::Tools.wrap do
          gateway.search_practitioners(query: query, location: location, limit: limit, diagnostics: diagnostics)
        end
      end
    end

    def register_get_booking_context(server, gateway)
      server.define_tool(
        name: "get_booking_context",
        description: "Retrieve public manual booking-context identifiers for a profile without reserving or booking.",
        input_schema: {
          type: "object",
          required: ["profile_ref"],
          properties: {
            profile_ref: { type: ["string", "integer"] },
            diagnostics: { type: "boolean" }
          },
          additionalProperties: false
        }
      ) do |profile_ref:, diagnostics: false|
        TocdocMcp::Tools.wrap { gateway.get_booking_context(profile_ref: profile_ref, diagnostics: diagnostics) }
      end
    end

    def register_search_availabilities(server, gateway)
      server.define_tool(
        name: "search_availabilities",
        description: "Search visible appointment slots using identifiers selected from booking context.",
        input_schema: {
          type: "object",
          required: ["profile_ref", "visit_motive_id", "agenda_ids"],
          properties: {
            profile_ref: { type: ["string", "integer"] },
            visit_motive_id: { type: ["string", "integer"] },
            agenda_ids: {
              oneOf: [
                { type: "array", items: { type: ["string", "integer"] }, minItems: 1 },
                { type: ["string", "integer"] }
              ]
            },
            practice_ids: {
              oneOf: [
                { type: "array", items: { type: ["string", "integer"] } },
                { type: ["string", "integer"] }
              ]
            },
            start_date: { type: "string" },
            limit: { type: "integer", minimum: 1 },
            telehealth: { type: "boolean" },
            diagnostics: { type: "boolean" }
          },
          additionalProperties: false
        }
      ) do |profile_ref:, visit_motive_id:, agenda_ids:, practice_ids: nil,
             start_date: nil, limit: 10, telehealth: nil, diagnostics: false|
        TocdocMcp::Tools.wrap do
          gateway.search_availabilities(
            profile_ref: profile_ref,
            visit_motive_id: visit_motive_id,
            agenda_ids: agenda_ids,
            practice_ids: practice_ids,
            start_date: start_date,
            limit: limit,
            telehealth: telehealth,
            diagnostics: diagnostics
          )
        end
      end
    end

    def wrap
      ToolResponse.success(yield)
    rescue TocdocMcp::Error => e
      ToolResponse.error(e)
    end
  end
end
