ARG PG_CONTAINER_VERSION=14.5

FROM docker.io/library/postgres:${PG_CONTAINER_VERSION}-bullseye as builder

RUN apt-get update \
 && apt-get install -y postgresql-server-dev-14 \
    build-essential \
    autoconf \
    libzstd-dev \
    libz-dev \
    liblz4-dev \
    libcurl4-openssl-dev \
    git \
    curl

RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y nodejs

ARG CHECKOUT_VERSION=main

RUN git clone https://github.com/hydradatabase/hydra && \
    cd hydra/columnar && \
    git checkout ${CHECKOUT_VERSION} && \
    ./configure && \
    make && \
    make install

FROM postgres:${PG_CONTAINER_VERSION}-bullseye
COPY --from=builder /usr/lib/postgresql/14/lib/* /usr/lib/postgresql/14/lib/
COPY --from=builder /usr/share/postgresql/14/extension/* /usr/share/postgresql/14/extension/
COPY --from=builder /usr/bin/curl /usr/bin/curl
COPY --from=builder /usr/bin/node /usr/bin/node
COPY --from=builder /usr/lib/node_modules /usr/lib/node_modules

#RUN /benchmarks
#COPY ./initdb.d /docker-entrypoint-initdb.d

