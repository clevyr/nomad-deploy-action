FROM python:3-alpine

ARG NOMAD_VERSION=0.10.2
ENV NOMAD_VERSION=$NOMAD_VERSION

RUN set -x \
    && apk add \
        --repository http://dl-cdn.alpinelinux.org/alpine/edge/testing \
        nomad \
    && apk add \
        bind-tools \
    && pip --no-cache-dir install \
        awscli \
    && rm -rf /var/cache/apk/*

COPY rootfs/ /

ENTRYPOINT ["/entrypoint"]
