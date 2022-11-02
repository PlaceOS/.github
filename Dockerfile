# Test Container
###############################################################################
ARG crystal_version=latest
FROM placeos/crystal:${crystal_version} as test

WORKDIR /app

# - Add watchexec for running tests on change
# hadolint ignore=DL3018
RUN apk add \
  --update \
  --no-cache \
  --repository=https://dl-cdn.alpinelinux.org/alpine/edge/testing \
    watchexec

COPY test-scripts /app/scripts

ENTRYPOINT ["/app/scripts/test-entrypoint.sh"]
