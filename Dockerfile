FROM ruby:4.0-slim

WORKDIR /app

ENV BUNDLE_DEPLOYMENT=true \
    BUNDLE_WITHOUT=development:test \
    HOST=0.0.0.0 \
    PORT=8080

RUN apt-get update \
  && apt-get install -y --no-install-recommends build-essential ca-certificates \
  && rm -rf /var/lib/apt/lists/*

COPY Gemfile Gemfile.lock ./
RUN bundle install

COPY . .

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
  CMD ruby -rnet/http -ruri -e 'uri = URI("http://127.0.0.1:#{ENV.fetch("PORT", "8080")}/health"); exit(Net::HTTP.get_response(uri).is_a?(Net::HTTPSuccess) ? 0 : 1)'

CMD ["bundle", "exec", "ruby", "bin/tocdoc-mcp-http"]
