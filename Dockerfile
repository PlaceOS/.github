# Test Container
###############################################################################

FROM placeos/crystal:latest as test

WORKDIR /app

# - Add watchexec for running tests on change (don't use edge repo)
# --repository=https://dl-cdn.alpinelinux.org/alpine/edge/testing \
# hadolint ignore=DL3018
RUN apk add \
  --update \
  --no-cache \
    watchexec

COPY test-scripts /app/scripts

ENTRYPOINT ["/app/scripts/test-entrypoint.sh"]
