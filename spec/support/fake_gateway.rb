# frozen_string_literal: true

module SpecSupport
  class FakeGateway
    attr_reader :calls

    def initialize(responses: {})
      @calls = []
      @responses = responses
    end

    def respond_with(method_name, response)
      @responses[method_name] = response
    end

    def search_practitioners(**args)
      record(:search_practitioners, args)
    end

    def get_booking_context(**args)
      record(:get_booking_context, args)
    end

    def search_availabilities(**args)
      record(:search_availabilities, args)
    end

    private

    def record(method_name, args)
      @calls << [method_name, args]
      response = @responses.fetch(method_name) { { ok: true, method: method_name, args: args } }
      raise response if response.is_a?(Exception)

      response
    end
  end
end
