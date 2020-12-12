FROM elixir:1.11.2-alpine as builder

LABEL company="Uniris"
LABEL version="0.9.1"

ENV LANG C.UTF-8 \
  REFRESHED_AT 2020-12-10-1 \
  TERM xterm \
  DEBIAN_FRONTEND noninteractive
ENV ELIXIR_VERSION v1.11.2
ENV VERSION 0.9.1

ENV MIX_ENV prod

# Install system requirements
RUN apk add --no-cache --update
    openssl \
    build-base \
    gcc \
    git \
    npm \
    python3 \
    wget

# Install Libsodium
RUN wget https://download.libsodium.org/libsodium/releases/LATEST.tar.gz && \
    mkdir /opt/libsodium && \
    tar zxvf LATEST.tar.gz -C /opt/libsodium && \
    cd /opt/libsodium/libsodium-stable && \
    ./configure && \
    make && \
    make install

WORKDIR /opt/server-builder/
COPY . /opt/server-builder/

# Install dependencies
# Cache Elixir deps
RUN mix local.hex --force && mix local.rebar --force
RUN mix do deps.get --only prod, deps.compile --force
RUN mix deps.clean mime --build 
RUN mix distillery.release --env=prod

RUN mkdir /opt/server \
  && tar xvzf ./_build/prod/rel/server/releases/${VERSION}/server.tar.gz -C /opt/server

# Cache Node deps
RUN npm install
RUN npm run deploy

# RUN mix phx.digest

RUN rm -rf /opt/server-builder

#############################################################

FROM alpine:3.12

LABEL company="Uniris"
LABEL version="0.9.1"

ENV LANG C.UTF-8 \
  REFRESHED_AT 2020-12-10-1 \
  TERM xterm \
  DEBIAN_FRONTEND noninteractive

ENV REPLACE_OS_VARS=true \
  HOSTNAME=${HOSTNAME} \
  UNIRIS_CRYPTO_SEED=${UNIRIS_CRYPTO_SEED} \
  UNIRIS_P2P_PORT=${UNIRIS_P2P_PORT} \
  ERL_CRASH_DUMP_SECONDS=10 \
  HEART_BEAT_TIMEOUT=30 \
  HEART_KILL_SIGNAL=SIGABRT \
  HEART_NO_KILL=0 \
  HEART_COMMAND=reboot

RUN apk add --update \
  bash \
  openssl

COPY --from=builder /opt/server /usr/local/bin/server
WORKDIR /usr/local/bin/server/bin

EXPOSE 80

CMD /bin/bash