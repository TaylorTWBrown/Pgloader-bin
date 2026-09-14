FROM debian:bookworm-slim AS builder

ARG TARGETPLATFORM
ARG TARGETARCH
ARG BUILDPLATFORM

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        bzip2 \
        ca-certificates \
        curl \
        freetds-dev \
        gawk \
        git \
        libsqlite3-dev \
        libssl3 \
        libzip-dev \
        make \
        openssl \
        patch \
        sbcl \
        time \
        unzip \
        wget \
        cl-ironclad \
        cl-babel && \
    mkdir -p /opt/src/pgloader && \
    rm -rf /var/lib/apt/lists/*

RUN wget -O /tmp/pgloader.tar.gz -L \
        "https://github.com/tobz/pgloader/archive/refs/heads/master.tar.gz" && \
    tar xf \
        /tmp/pgloader.tar.gz -C /opt/src/pgloader --strip-components=1

RUN echo "Building on ${BUILDPLATFORM} for ${TARGETPLATFORM} (${TARGETARCH})"

RUN mkdir -p /opt/src/pgloader/build/bin && \
    cd /opt/src/pgloader && \
    make DYNSIZE=32768 clones save

FROM debian:bookworm-slim

ARG TARGETPLATFORM
ARG TARGETARCH

LABEL maintainer=Roxedus
LABEL org.opencontainers.image.description="pgloader binary container for ${TARGETPLATFORM} (${TARGETARCH})"

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        curl \
        freetds-dev \
        gawk \
        libsqlite3-dev \
        libzip-dev \
        make \
        sbcl \
        unzip && \
    rm -rf /var/lib/apt/lists/*

COPY --from=builder /opt/src/pgloader/build/bin/pgloader /usr/local/bin

ENTRYPOINT [ "pgloader" ]
