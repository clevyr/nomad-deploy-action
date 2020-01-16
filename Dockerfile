FROM python:3-alpine

ARG NOMAD_VERSION=0.10.2
ENV NOMAD_VERSION=$NOMAD_VERSION

RUN set -x \
    && apk add \
        bind-tools \
    && apk add --virtual .build-deps \
        curl \
    && pip --no-cache-dir install \
        awscli \
    && curl -Lsf -o nomad.zip \
        "https://releases.hashicorp.com/nomad/${NOMAD_VERSION}/nomad_${NOMAD_VERSION}_linux_amd64.zip" \
    && unzip nomad.zip \
    && mv nomad /usr/bin/nomad \
    && rm nomad.zip \
    && apk del .build-deps \
    && rm -rf /var/cache/apk/*

COPY rootfs/ /

ENTRYPOINT ["/entrypoint"]
