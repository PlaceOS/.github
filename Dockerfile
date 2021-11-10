ARG CRYSTAL_VERSION=1.1.1

FROM flant/kcov-alpine:v0.6 as kcov
WORKDIR /wd

# Extract binary dependencies
RUN for binary in "/usr/bin/kcov"; do \
        ldd "$binary" | \
        tr -s '[:blank:]' '\n' | \
        grep '^/' | \
        xargs -I % sh -c 'mkdir -p $(dirname deps%); cp % deps%;'; \
    done

# Test Container
###############################################################################

FROM crystallang/crystal:${CRYSTAL_VERSION}-alpine as test

# Add kcov
COPY --from=kcov /wd/deps /
COPY --from=kcov /usr/bin/kcov /usr/bin/kcov


# Build crystal kcov tool
WORKDIR /app
RUN git clone --depth=1 https://github.com/Vici37/crystal-kcov
WORKDIR /app/crystal-kcov
RUN shards build && \
    mv bin/crkcov /usr/bin/crkcov
WORKDIR /app
RUN rm -rf crystal-kcov

WORKDIR /app

# Set the commit through a build arg
ARG PLACE_COMMIT="DEV"

# - Add trusted CAs for communicating with external services
# - Add watchexec for running tests on change
RUN apk add --no-cache \
        bash \
        ca-certificates \
        iputils \
        libelf \
        libssh2-static \
        yaml-static \
    && \
    apk add --no-cache -X http://dl-cdn.alpinelinux.org/alpine/edge/testing \
        watchexec \
    && \
    update-ca-certificates

COPY test-scripts /app/scripts

# These provide certificate chain validation where communicating with external services over TLS
ENV SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt

ENTRYPOINT ["/app/scripts/test-entrypoint.sh"]
