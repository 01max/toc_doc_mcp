# frozen_string_literal: true

require "yaml"

RSpec.describe "Docker packaging" do
  it "defines an HTTP service image without baked secrets" do
    dockerfile = File.read("Dockerfile")

    expect(dockerfile).to include('CMD ["bundle", "exec", "ruby", "bin/tocdoc-mcp-http"]')
    expect(dockerfile).to include("Gemfile.lock")
    expect(dockerfile).not_to include("MCP_AUTH_TOKEN=")
  end

  it "keeps non-runtime files out of the image context" do
    dockerignore = File.read(".dockerignore")

    expect(dockerignore).to include(".git")
    expect(dockerignore).to include("openspec")
    expect(dockerignore).to include("spec")
  end

  it "provides an environment example without real secrets" do
    env_example = File.read(".env.example")

    expect(env_example).to include("MCP_AUTH_TOKEN=replace-with-a-long-random-token")
    expect(env_example).to include("PORT=8080")
    expect(env_example).not_to include("valid-token-123")
  end

  it "defines compose runtime configuration and health check without tunnel services" do
    compose = YAML.safe_load_file("docker-compose.yml")
    service = compose.fetch("services").fetch("tocdoc-mcp")

    expect(service.fetch("env_file")).to include(".env")
    expect(service.fetch("ports")).to include("8080:8080")
    expect(service.fetch("healthcheck").fetch("test").join(" ")).to include("/health")
    expect(compose.fetch("services").keys).not_to include("cloudflared")
  end
end
