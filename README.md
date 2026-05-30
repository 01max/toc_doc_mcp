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

## Test

```sh
bundle exec rake
```
