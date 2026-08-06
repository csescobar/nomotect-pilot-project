# syntax=docker/dockerfile:1.7
ARG RUBY_VERSION=4.0.5
ARG OCI_SOURCE=local://repository
ARG OCI_REVISION=unknown
ARG OCI_CREATED=1970-01-01T00:00:00Z
ARG OCI_VERSION=0.0.0-dev
ARG OCI_TITLE="Rails Application"
ARG OCI_DESCRIPTION="Rails and Hotwire application container"
FROM ruby:${RUBY_VERSION}-slim-bookworm AS base

WORKDIR /rails

ENV RAILS_ENV="production" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development:test"

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y curl libjemalloc2 libpq5 && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*

FROM base AS build

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential git libpq-dev pkg-config && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*

COPY Gemfile Gemfile.lock ./
RUN bundle config set frozen true && \
    bundle install && \
    rm -rf /root/.bundle "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git

COPY . .
RUN SECRET_KEY_BASE=aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa \
    bundle exec rails assets:precompile

FROM base AS development

ENV RAILS_ENV="development" \
    BUNDLE_WITHOUT=""

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
      bash-completion \
      build-essential \
      git \
      less \
      libpq-dev \
      pkg-config \
      postgresql-client \
      procps && \
    rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*

ARG DEV_UID=1000
ARG DEV_GID=1000
RUN groupadd --gid ${DEV_GID} vscode && \
    useradd vscode --uid ${DEV_UID} --gid ${DEV_GID} --create-home --shell /bin/bash && \
    mkdir -p /usr/local/bundle /rails && \
    chown -R vscode:vscode /usr/local/bundle /rails

USER vscode
CMD ["sleep", "infinity"]

FROM base

ARG APP_UID=1000
ARG APP_GID=1000
ARG OCI_SOURCE
ARG OCI_REVISION
ARG OCI_CREATED
ARG OCI_VERSION
ARG OCI_TITLE
ARG OCI_DESCRIPTION
RUN groupadd --system --gid ${APP_GID} rails && \
    useradd rails --uid ${APP_UID} --gid ${APP_GID} --create-home --shell /bin/bash

COPY --from=build /usr/local/bundle /usr/local/bundle
COPY --from=build --chown=rails:rails /rails /rails

RUN mkdir -p log tmp/pids tmp/cache storage var/installation && \
    chown -R rails:rails log tmp storage var

LABEL org.opencontainers.image.title="${OCI_TITLE}" \
      org.opencontainers.image.description="${OCI_DESCRIPTION}" \
      org.opencontainers.image.source="${OCI_SOURCE}" \
      org.opencontainers.image.revision="${OCI_REVISION}" \
      org.opencontainers.image.created="${OCI_CREATED}" \
      org.opencontainers.image.version="${OCI_VERSION}" \
      org.opencontainers.image.licenses="Apache-2.0" \
      io.rails-platform.persistence="/rails/storage,/rails/var/installation"

USER rails

ENV PORT="3000" \
    MALLOC_CONF="dirty_decay_ms:1000,narenas:2,background_thread:true"

EXPOSE 3000

ENTRYPOINT ["bash", "bin/container-entrypoint"]
CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]

HEALTHCHECK --interval=10s --timeout=3s --start-period=30s --retries=5 \
  CMD curl --fail --silent --show-error http://127.0.0.1:${PORT}/health || exit 1
