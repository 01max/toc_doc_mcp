# TocDoc MCP Server

Read-only MCP server for discovering public practitioner information and visible appointment availability through the `toc_doc` Ruby gem.

## Requirements

- Ruby 3.1 or newer
- Bundler

## Install

```sh
bundle install
```

## Run Locally

```sh
bundle exec ruby bin/tocdoc-mcp
```

The local entrypoint uses MCP stdio transport and does not open a network listener.

The bootstrap tool catalog is intentionally read-only:

- `search_practitioners`
- `get_booking_context`
- `search_availabilities`

`location` on practitioner search is treated as an optional search hint, not as a guaranteed radius, coordinate, city, or postal-code filter.

## Test

```sh
bundle exec rake
```

## Smoke Testing

For manual smoke testing, use a dynamic public-data flow instead of committed real-person fixtures:

1. Search with a broad query such as `dentiste Metz`, `medecin generaliste Metz`, or `dermatologue Metz`.
2. Pick a returned `profile_ref`.
3. Call `get_booking_context` with that `profile_ref`.
4. Use returned `visit_motive_id`, `agenda_ids`, and optional `practice_ids` values with `search_availabilities`.

Availability can legitimately be empty.

## Current Limitations

This bootstrap release does not implement HTTP transport, bearer-token authentication, Docker packaging, Cloudflare Tunnel exposure, rate limiting, persistent storage, or monitoring. Those belong in follow-up changes after the local read-only tool contract is stable.

The server never exposes booking, cancellation, login, account-management, slot reservation, or other mutating tools.
