# Test Container
###############################################################################

ARG CRYSTAL_VERSION=1.6.1
FROM placeos/crystal:${CRYSTAL_VERSION} as test

WORKDIR /app

# Set the commit through a build arg
ARG PLACE_COMMIT="DEV"

# - Add trusted CAs for communicating with external services
# - Add watchexec for running tests on change
# hadolint ignore=DL3018
RUN apk add --no-cache \
        bash \
        ca-certificates \
        curl \
        iputils \
        libelf \
        libssh2-static \
        lz4-dev \
        lz4-static \
        yaml-static \
    && \
    apk add --repository=https://dl-cdn.alpinelinux.org/alpine/edge/testing \
        watchexec \
    && \
    update-ca-certificates

COPY test-scripts /app/scripts

# Create a non-privileged user
# ARG IMAGE_UID="10001"
# ENV UID=$IMAGE_UID
# ENV USER=appuser
# RUN adduser \
#         --disabled-password \
#         --gecos "" \
#         --home "/app" \
#         --shell "/bin/bash" \
#         --uid "${UID}" \
#         "${USER}" \
#     && \
#     chown -R appuser /app
#
# USER appuser:appuser

# These provide certificate chain validation where communicating with external services over TLS
ENV SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt

ENTRYPOINT ["/app/scripts/test-entrypoint.sh"]
