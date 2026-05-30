# TocDoc MCP Server

Read-only MCP server for discovering public practitioner information and visible appointment availability through the `toc_doc` Ruby gem.

## Requirements

- Ruby 3.3 or newer
- Bundler
- Docker, for container deployment

## Install

```sh
bundle install
```

## Run Locally

Stdio mode:

```sh
bundle exec ruby bin/tocdoc-mcp
```

The local entrypoint uses MCP stdio transport and does not open a network listener.

HTTP mode:

```sh
MCP_AUTH_TOKEN="use-a-long-random-token" bundle exec ruby bin/tocdoc-mcp-http
```

By default the HTTP server listens on `0.0.0.0:8080`. Override with `HOST` and `PORT`.

Authenticated MCP requests are served at `/mcp`:

```sh
curl \
  -H "Authorization: Bearer use-a-long-random-token" \
  -H "Accept: application/json, text/event-stream" \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":1,"method":"tools/list"}' \
  http://127.0.0.1:8080/mcp
```

Unauthenticated health checks are served at `/health` and do not expose tools or upstream data:

```sh
curl http://127.0.0.1:8080/health
```

The bootstrap tool catalog is intentionally read-only:

- `search_practitioners`
- `get_booking_context`
- `search_availabilities`

`location` on practitioner search is treated as an optional search hint, not as a guaranteed radius, coordinate, city, or postal-code filter.

## Test

```sh
bundle exec rake
```

## Docker

Create a local `.env` from the example and replace the token:

```sh
cp .env.example .env
```

Then run:

```sh
docker compose up --build
```

The container runs the authenticated HTTP server by default. If you expose it through a tunnel or reverse proxy, target the service at `http://tocdoc-mcp:8080/mcp` inside the compose network or `http://127.0.0.1:8080/mcp` from the host.

## Smoke Testing

For manual smoke testing, use a dynamic public-data flow instead of committed real-person fixtures:

1. Search with a broad query such as `dentiste Metz`, `medecin generaliste Metz`, or `dermatologue Metz`.
2. Pick a returned `profile_ref`.
3. Call `get_booking_context` with that `profile_ref`.
4. Use returned `visit_motive_id`, `agenda_ids`, and optional `practice_ids` values with `search_availabilities`.

Availability can legitimately be empty.

## Current Limitations

This bootstrap release does not implement OAuth, per-user tokens, Cloudflare Tunnel lifecycle management, rate limiting, persistent storage, or monitoring.

The server never exposes booking, cancellation, login, account-management, slot reservation, or other mutating tools.
