# Image for running the API with Docker (see docker-compose.yml).
FROM ruby:3.2.3-slim

RUN apt-get update -qq \
 && apt-get install -y --no-install-recommends build-essential default-libmysqlclient-dev pkg-config git \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# The official image keeps gems and bundler config in /usr/local/bundle.
COPY Gemfile Gemfile.lock ./
RUN bundle install --jobs 4

COPY . .
RUN mkdir -p tmp/pids log

EXPOSE 3000
CMD ["bin/rails", "server", "-b", "0.0.0.0", "-p", "3000"]
