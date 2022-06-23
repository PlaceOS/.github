ARG CRYSTAL_VERSION=1.4.1

# Build kcov
###############################################################################
# using 3.12 to match the version used by crystal
FROM alpine:3.12 as kcov

SHELL ["/bin/ash", "-eo", "pipefail", "-c"]

RUN apk update && \
    apk add --no-cache \
    curl \
    cmake \
    make \
    gcc \
    g++ \
    binutils-dev \
    zlib-dev \
    curl-dev \
    elfutils-dev \
    python3

WORKDIR /kcov
ENV KCOV_VERSION=40 CXXFLAGS="-D__ptrace_request=int"
RUN mkdir -p kcov-$KCOV_VERSION/build bin && \
    curl --location https://github.com/SimonKagstrom/kcov/archive/v$KCOV_VERSION.tar.gz \
    | tar xzC ./ && \
    cd kcov-$KCOV_VERSION/build && \
    cmake \
    -Wno-dev \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=/local \
    .. && \
    make --jobs 2 || exit 1 && \
    make install DESTDIR=/usr || exit 1

# Extract binary dependencies
RUN for binary in "/usr/local/bin/kcov"; do \
        ldd "$binary" | \
        tr -s '[:blank:]' '\n' | \
        grep '^/' | \
        xargs -I % sh -c 'mkdir -p $(dirname deps%); cp % deps%;'; \
    done

# Test Container
###############################################################################
FROM crystallang/crystal:${CRYSTAL_VERSION}-alpine as test

# Add kcov
COPY --from=kcov /kcov/deps /
COPY --from=kcov /usr/local/bin/kcov /usr/bin/kcov

# Build crystal kcov tool
WORKDIR /app
RUN git clone --depth=1 https://github.com/Vici37/crystal-kcov
WORKDIR /app/crystal-kcov
RUN shards build && \
    mv bin/crkcov /usr/bin/crkcov

WORKDIR /app

RUN rm -rf crystal-kcov

# Set the commit through a build arg
ARG PLACE_COMMIT="DEV"

# - Add trusted CAs for communicating with external services
# - Add watchexec for running tests on change
RUN apk upgrade --no-cache apk \
    && \
    apk add --no-cache \
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
    apk add --no-cache -X http://dl-cdn.alpinelinux.org/alpine/edge/testing \
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
