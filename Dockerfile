ARG CRYSTAL_VERSION=1.4.1

# Build kcov
###############################################################################
# using 3.12 to match the version used by crystal
FROM alpine:3.12 as kcov
SHELL ["/bin/ash", "-euo", "pipefail", "-c"]

# hadolint ignore=DL3018
RUN apk upgrade --no-cache apk \
 && apk add --update --no-cache \
    build-base \
    cmake \
    ninja \
    python3 \
    binutils-dev \
    curl-dev \
    elfutils-dev

WORKDIR /kcov
ENV KCOV_VERSION=40
# hadolint ignore=DL3003
RUN wget -q "https://github.com/SimonKagstrom/kcov/archive/v$KCOV_VERSION.tar.gz" -O - | tar xz -C ./ --strip-components 1 \
 && mkdir build \
 && cd build \
 && CXXFLAGS="-D__ptrace_request=int" cmake -G Ninja .. \
 && cmake --build . --target install

# Test Container
###############################################################################
FROM crystallang/crystal:${CRYSTAL_VERSION}-alpine as test
SHELL ["/bin/ash", "-euo", "pipefail", "-c"]

# - Add kcov dependencies
# - Add trusted CAs for communicating with external services
# - Add watchexec for running tests on change
# hadolint ignore=DL3018
RUN apk upgrade --no-cache apk \
 && apk add --update --no-cache \
    bash \
    python3 \
    binutils-dev \
    curl-dev \
    elfutils-libelf \
    ca-certificates \
    curl \
    iputils \
    libelf \
    libssh2-static \
    lz4-dev \
    lz4-static \
    yaml-static \
 && apk add --no-cache -X http://dl-cdn.alpinelinux.org/alpine/edge/testing \
    watchexec \
 && update-ca-certificates

# Add kcov
COPY --from=kcov /usr/local/bin/kcov* /usr/local/bin/
COPY --from=kcov /usr/local/share/doc/kcov /usr/local/share/doc/kcov

# Build crystal-coverage tool
WORKDIR /crystal-coverage
RUN git clone --depth=1 https://github.com/lbguilherme/crystal-coverage . \
 && shards build --production --release \
 && mv bin/crystal-coverage /usr/bin/

WORKDIR /app
RUN rm -rf /crystal-coverage

# Set the commit through a build arg
ARG PLACE_COMMIT="DEV"

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
