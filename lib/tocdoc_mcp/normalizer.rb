# frozen_string_literal: true

module TocdocMcp
  module Normalizer
    module_function

    def profile_candidate(profile)
      data = to_hash(profile)
      {
        profile_ref: normalized_ref(data),
        display_name: display_name(profile, data),
        kind: profile_kind(profile, data),
        labels: compact_array(data["specialities"] || data["speciality"] || data["label"]),
        location: location_summary(data),
        source_url: profile_url(data)
      }.compact
    end

    def booking_context(info, profile_ref:)
      data = info.to_h
      {
        profile_ref: profile_ref,
        profile: normalized_profile(data["profile"]),
        specialities: Array(data["specialities"]).map { |item| speciality(item) },
        visit_motives: Array(data["visit_motives"]).map { |item| visit_motive(item) },
        agendas: Array(data["agendas"]).map { |item| agenda(item) },
        places: Array(data["places"]).map { |item| place(item) },
        practitioners: Array(data["practitioners"]).map { |item| normalized_profile(item) }
      }
    end

    def availabilities(collection, profile_ref:, visit_motive_id:, agenda_ids:, practice_ids:, telehealth:)
      slots = collection.slots.map do |slot|
        {
          start_time: slot.iso8601,
          visit_motive_id: visit_motive_id,
          agenda_ids: agenda_ids,
          practice_ids: practice_ids,
          telehealth: telehealth
        }.compact
      end

      {
        profile_ref: profile_ref,
        visit_motive_id: visit_motive_id,
        agenda_ids: agenda_ids,
        practice_ids: practice_ids,
        telehealth: telehealth,
        slots: slots,
        total: safe_send(collection, :total),
        next_slot: safe_send(collection, :next_slot),
        booking_url: safe_send(collection, :booking_url)
      }.compact
    end

    def normalized_profile(data)
      data = to_hash(data)
      {
        profile_ref: normalized_ref(data),
        display_name: first_present(data, "name_with_title", "name", "label"),
        kind: data["organization"] ? "organization" : "practitioner",
        location: location_summary(data),
        source_url: profile_url(data)
      }.compact
    end

    def visit_motive(data)
      data = to_hash(data)
      {
        id: data["id"],
        name: data["name"],
        telehealth: first_present(data, "telehealth", "is_telehealth")
      }.compact
    end

    def agenda(data)
      data = to_hash(data)
      {
        id: data["id"],
        practice_id: data["practice_id"],
        visit_motive_ids: data["visit_motive_ids"],
        practitioner_id: first_present(data, "practitioner_id", "account_id")
      }.compact
    end

    def place(data)
      data = to_hash(data)
      {
        id: data["id"],
        city: data["city"],
        zipcode: data["zipcode"],
        full_address: data["full_address"],
        formal_name: data["formal_name"]
      }.compact
    end

    def speciality(data)
      data = to_hash(data)
      {
        id: data["id"],
        name: data["name"] || data["label"]
      }.compact
    end

    def to_hash(value)
      value.respond_to?(:to_h) ? value.to_h : value.to_h
    rescue NoMethodError
      {}
    end

    def display_name(profile, data)
      profile.to_s unless profile.to_s.start_with?("#<")
    rescue StandardError
      nil
    ensure
      return first_present(data, "name_with_title", "name", "label") if data
    end

    def profile_kind(profile, data)
      return "organization" if profile.respond_to?(:organization?) && profile.organization?
      return "practitioner" if profile.respond_to?(:practitioner?) && profile.practitioner?

      data["owner_type"] == "Organization" ? "organization" : "practitioner"
    end

    def location_summary(data)
      places = compact_array(data["places"])
      place = places.first
      return place_summary(place) if place

      first_present(data, "full_address", "city", "address")
    end

    def place_summary(place)
      data = to_hash(place)
      first_present(data, "full_address", "city", "address")
    end

    def profile_url(data)
      return data["url"] if data["url"]

      slug = first_present(data, "slug", "link")
      return unless slug

      slug.start_with?("http") ? slug : "https://www.doctolib.fr/#{slug}"
    end

    def first_present(data, *keys)
      keys.lazy.map { |key| data[key] }.find { |value| present?(value) }
    end

    def normalized_ref(data)
      first_present(data, "slug", "id", "value")&.to_s
    end

    def compact_array(value)
      Array(value).compact.reject { |item| item.respond_to?(:empty?) && item.empty? }
    end

    def present?(value)
      !value.nil? && !(value.respond_to?(:empty?) && value.empty?)
    end

    def safe_send(object, method_name)
      object.public_send(method_name) if object.respond_to?(method_name)
    end
  end
end
