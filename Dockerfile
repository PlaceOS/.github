# Test Container
###############################################################################
ARG crystal_version=latest
FROM placeos/crystal:${crystal_version} as test

WORKDIR /app

# - Add sqlite3
RUN apk update && apk upgrade
RUN apk add --no-cache sqlite-dev && \
 ln -sf /usr/lib/libsqlite3.so.0 /usr/lib/libsqlite3.so

# - Add watchexec for running tests on change
# hadolint ignore=DL3018
RUN apk add \
  --update \
  --no-cache \
  --repository=https://dl-cdn.alpinelinux.org/alpine/edge/community \
  watchexec


COPY test-scripts /app/scripts

ENTRYPOINT ["/app/scripts/test-entrypoint.sh"]
