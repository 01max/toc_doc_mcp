# frozen_string_literal: true

require "date"
require "timeout"
require "toc_doc"

require_relative "errors"
require_relative "normalizer"

module TocdocMcp
  class Gateway
    DEFAULT_LIMIT = 10

    def search_practitioners(query:, location: nil, limit: DEFAULT_LIMIT, diagnostics: false)
      query = require_text(query, "query")
      limit = normalize_limit(limit)
      search_query = [query, optional_text(location)].compact.join(" ")

      profiles = with_upstream_errors do
        TocDoc::Search.where(query: search_query, type: "profile")
      end

      candidates = Array(profiles).first(limit).map { |profile| Normalizer.profile_candidate(profile) }
      result = {
        query: query,
        location: optional_text(location),
        candidates: candidates
      }

      add_diagnostics(result, diagnostics, source: profiles, counts: { candidates: candidates.length })
    end

    def get_booking_context(profile_ref:, diagnostics: false)
      profile_ref = require_text(profile_ref, "profile_ref")

      info = with_upstream_errors do
        TocDoc::BookingInfo.find(profile_ref)
      end

      context = Normalizer.booking_context(info, profile_ref: profile_ref)
      add_diagnostics(context, diagnostics, source: info, counts: {
        visit_motives: context[:visit_motives].length,
        agendas: context[:agendas].length,
        places: context[:places].length
      })
    end

    def search_availabilities(profile_ref:, visit_motive_id:, agenda_ids:, practice_ids: nil,
                              start_date: nil, limit: DEFAULT_LIMIT, telehealth: nil,
                              diagnostics: false)
      profile_ref = require_text(profile_ref, "profile_ref")
      visit_motive_id = require_text(visit_motive_id, "visit_motive_id")
      agenda_ids = require_ids(agenda_ids, "agenda_ids")
      practice_ids = normalize_ids(practice_ids)
      limit = normalize_limit(limit)
      start_date = normalize_start_date(start_date)

      options = {}
      options[:practice_ids] = practice_ids unless practice_ids.empty?
      options[:telehealth] = telehealth unless telehealth.nil?
      options[:booking_slug] = profile_ref unless numeric_string?(profile_ref)

      collection = with_upstream_errors do
        TocDoc::Availability.where(
          visit_motive_ids: visit_motive_id,
          agenda_ids: agenda_ids,
          start_date: start_date,
          limit: limit,
          **options
        )
      end

      result = Normalizer.availabilities(
        collection,
        profile_ref: profile_ref,
        visit_motive_id: visit_motive_id,
        agenda_ids: agenda_ids,
        practice_ids: practice_ids,
        telehealth: telehealth
      )
      add_diagnostics(result, diagnostics, source: collection, counts: { slots: result[:slots].length })
    end

    private

    def with_upstream_errors
      yield
    rescue TocDoc::NotFound
      raise NotFoundError
    rescue ::Timeout::Error
      raise TimeoutError
    rescue TocDoc::Error
      raise UpstreamError
    end

    def require_text(value, field)
      text = optional_text(value)
      raise ValidationError, "#{field} is required" if text.nil?

      text
    end

    def optional_text(value)
      text = value.to_s.strip
      text.empty? ? nil : text
    end

    def normalize_limit(value)
      limit = Integer(value || DEFAULT_LIMIT)
      return limit if limit.positive?

      raise ValidationError, "limit must be greater than zero"
    rescue ArgumentError, TypeError
      raise ValidationError, "limit must be an integer"
    end

    def normalize_start_date(value)
      return Date.today if optional_text(value).nil?

      Date.parse(value.to_s)
    rescue Date::Error
      raise ValidationError, "start_date must be an ISO-8601 date"
    end

    def require_ids(value, field)
      ids = normalize_ids(value)
      raise ValidationError, "#{field} is required" if ids.empty?

      ids
    end

    def normalize_ids(value)
      return [] if value.nil?

      Array(value).flat_map { |item| item.to_s.split(",") }
                  .map(&:strip)
                  .reject(&:empty?)
    end

    def numeric_string?(value)
      value.to_s.match?(/\A\d+\z/)
    end

    def add_diagnostics(result, enabled, source:, counts:)
      return result unless enabled

      result.merge(
        diagnostics: {
          source_class: source.class.name,
          counts: counts
        }
      )
    end
  end
end
