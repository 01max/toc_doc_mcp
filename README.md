# TocDoc MCP Server

Read-only MCP server for discovering public practitioner information and visible appointment availability on Doctolib through the `toc_doc` Ruby gem.

## Disclaimer

Using this software is not aligned with Doctolib's Terms of Service. This project is provided for research and entertainment purposes only. You are responsible for ensuring that any use complies with applicable laws, policies, and third-party terms.

## Table of Contents

- [Project Status](#project-status)
- [Current Limitations](#current-limitations)
- [Requirements](#requirements)
- [Install](#install)
- [Run Locally](#run-locally)
- [Docker](#docker)
- [Usage With Codex](#usage-with-codex)
- [Test](#test)
- [Smoke Testing](#smoke-testing)
- [License](#license)

## Project Status

⚠️ This is a local prototype, not a production-ready service. Run it locally for now.

🔐 The current HTTP mode uses bearer-token authentication only, has no user model, no rate limiting, no abuse protection, no monitoring, and no production secret-management story. Requests may involve sensitive health-search context, and exploratory agent use can be noisy against the upstream API, so avoid exposing this server publicly.

This talks to a shadow public API through the `toc_doc` gem. Use it responsibly, keep request volume low, and treat upstream behavior as unstable.

## Current Limitations

This bootstrap release does not implement OAuth, per-user tokens, Cloudflare Tunnel lifecycle management, rate limiting, persistent storage, or monitoring.

The server never exposes booking, cancellation, login, account-management, slot reservation, or other mutating tools.

`search_practitioners` is not a general practitioner directory search. The current `toc_doc` gem and available upstream endpoints behave more like autocomplete/profile lookup than like a structured search engine.

In practice, the query should include at least a partial practitioner, organization, or profile name. Vague requests such as `médecin généraliste Bordeaux`, `diététicien Bordeaux`, or `3 généralistes in Mérignac` can return no results or irrelevant matches.

`location` is only appended to the upstream search query as a hint. It is not a hard filter, radius search, coordinate search, postcode search, or city constraint.

The reliable workflow is:

1. Start from a known practitioner, organization, or profile name.
2. Use `search_practitioners` to resolve the `profile_ref`.
3. Use `get_booking_context` for motives, agendas, and practices.
4. Use `search_availabilities` for visible slots.

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

## Usage With Codex

Use the helper script for local Codex testing:

```sh
bin/tocdoc-codex-with-docker
```

The script generates a fresh local token, asks before creating or updating `.env`, builds and starts the Docker service, registers `tocdoc-local` with Codex if needed, warns when that MCP entry already exists, waits for `/health`, and then launches Codex with the token available to the MCP client. If any step fails, the script exits with an error.

Pass extra Codex CLI arguments after the script name:

```sh
bin/tocdoc-codex-with-docker --model gpt-5.5
```

Manual setup is also possible. Start the Dockerized server locally first:

```sh
cp .env.example .env
docker compose up --build
```

Use the same token from `.env` when registering the local HTTP MCP server with Codex:

```sh
export TOCDOC_MCP_TOKEN="use-the-same-token-as-MCP_AUTH_TOKEN"

codex mcp add tocdoc-local \
  --url http://127.0.0.1:8080/mcp \
  --bearer-token-env-var TOCDOC_MCP_TOKEN
```

Codex must see `TOCDOC_MCP_TOKEN` when it starts. For a one-off CLI session:

```sh
codex -c 'shell_environment_policy.set.TOCDOC_MCP_TOKEN="use-the-same-token-as-MCP_AUTH_TOKEN"'
```

For repeated local testing, add the token to `~/.codex/config.toml`:

```toml
[shell_environment_policy.set]
TOCDOC_MCP_TOKEN = "use-the-same-token-as-MCP_AUTH_TOKEN"
```

Then start a fresh Codex session and ask for a read-only search:

```text
what's the first dermatologist appointment available in bordeaux
```

Codex handles MCP initialization and session headers automatically. Raw `curl` calls may need an explicit `initialize` request and `Mcp-Session-Id` header unless `MCP_HTTP_STATELESS=true` is set.

## Test

```sh
bundle exec rake
```

## Smoke Testing

For manual smoke testing, use a dynamic public-data flow instead of committed real-person fixtures. Start with a known or partially known profile name whenever possible:

1. Search with a practitioner, organization, or profile name.
2. Pick a returned `profile_ref`.
3. Call `get_booking_context` with that `profile_ref`.
4. Use returned `visit_motive_id`, `agenda_ids`, and optional `practice_ids` values with `search_availabilities`.

Broad specialty-and-city searches can legitimately return empty or irrelevant results. Availability can also legitimately be empty.

Example local Codex query:

```text
what's the first dermatologist appointment available in bordeaux
```

Example result from a manual smoke test:

```text
Earliest slot found around Bordeaux:

Wednesday, June 3, 2026 at 16:00
Dr Héloïse BARAILLER
Centre de Dermatologie Bordeaux Mérignac, Mérignac 33700
Appointment type: Consultation dépistage mélanome / patient à risque / suivi carcinologique

Strictly Bordeaux city, using a more generic dermatology consultation:

Wednesday, July 15, 2026 at 09:00
Cabinet de dermatologie des docteurs Gey-Valiergue et Lalanne, Bordeaux 33000
Appointment type: Consultation

No visible available slots were found for "Première consultation de dermatologie" in the checked Bordeaux profiles.
```

Visible availability changes frequently, so treat example dates as historical smoke-test output rather than stable fixtures.

## License

This project is available under the [MIT License](LICENSE).
