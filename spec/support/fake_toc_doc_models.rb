# frozen_string_literal: true

module SpecSupport
  FakeProfile = Struct.new(:data, keyword_init: true) do
    def to_h
      data
    end

    def to_s
      data["name_with_title"] || data["name"]
    end

    def practitioner?
      true
    end

    def organization?
      false
    end
  end

  FakeBookingInfo = Struct.new(:payload, keyword_init: true) do
    def to_h
      payload
    end
  end

  FakeAvailabilityCollection = Struct.new(:slot_values, keyword_init: true) do
    def slots
      slot_values
    end

    def total
      slot_values.length
    end

    def next_slot
      nil
    end

    def booking_url
      "https://www.doctolib.fr/example/booking/motives"
    end
  end
end
