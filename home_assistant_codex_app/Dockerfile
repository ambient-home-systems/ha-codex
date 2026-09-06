ARG BUILD_FROM
FROM ${BUILD_FROM}

ARG TTYD_VERSION
ARG TRZSZ_VERSION
ARG CODEX_VERSION

ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    TERM=xterm-256color

# Codex is installed from a pinned GitHub release (CODEX_VERSION) rather than the
# always-latest installer, so a new Codex release cannot change the add-on's
# behavior until the pin is bumped. ttyd provides the terminal that Home
# Assistant exposes through Ingress. trzsz supplies the trz/tsz commands; ttyd's
# bundled client turns them into a browser file picker so files can be attached
# to (and downloaded from) the terminal.
RUN apk add --no-cache \
      bash \
      bubblewrap \
      ca-certificates \
      curl \
      git \
      grep \
      gzip \
      jq \
      nodejs \
      ripgrep \
      tar \
      tmux \
  && update-ca-certificates \
  && curl -fsSL "https://github.com/tsl0922/ttyd/releases/download/${TTYD_VERSION}/ttyd.x86_64" -o /usr/local/bin/ttyd \
  && chmod 0755 /usr/local/bin/ttyd \
  && curl -fsSL "https://github.com/trzsz/trzsz-go/releases/download/v${TRZSZ_VERSION}/trzsz_${TRZSZ_VERSION}_linux_x86_64.tar.gz" -o /tmp/trzsz.tar.gz \
  && mkdir -p /tmp/trzsz \
  && tar -xzf /tmp/trzsz.tar.gz -C /tmp/trzsz \
  && find /tmp/trzsz -type f \( -name trz -o -name tsz -o -name trzsz \) -exec install -m 0755 {} /usr/local/bin/ \; \
  && rm -rf /tmp/trzsz /tmp/trzsz.tar.gz \
  && trz --version \
  && curl -fsSL "https://github.com/openai/codex/releases/download/rust-v${CODEX_VERSION}/codex-x86_64-unknown-linux-musl.tar.gz" -o /tmp/codex.tar.gz \
  && mkdir -p /tmp/codex \
  && tar -xzf /tmp/codex.tar.gz -C /tmp/codex \
  && install -m 0755 "$(find /tmp/codex -type f -name 'codex*' ! -name '*.sigstore' | head -n 1)" /usr/local/bin/codex \
  && rm -rf /tmp/codex /tmp/codex.tar.gz \
  && curl -fsSL "https://github.com/openai/codex/releases/download/rust-v${CODEX_VERSION}/codex-code-mode-host-x86_64-unknown-linux-musl.tar.gz" -o /tmp/codex-code-mode-host.tar.gz \
  && mkdir -p /tmp/codex-code-mode-host \
  && tar -xzf /tmp/codex-code-mode-host.tar.gz -C /tmp/codex-code-mode-host \
  && set -- $(find /tmp/codex-code-mode-host -type f -perm /111 -name 'codex-code-mode-host*' \
      ! -name '*.sigstore' ! -name '*.sha256' ! -name '*.checksum'); \
     [ "$#" -eq 1 ] \
  && install -m 0755 "$1" /usr/local/bin/codex-code-mode-host \
  && rm -rf /tmp/codex-code-mode-host /tmp/codex-code-mode-host.tar.gz \
  && codex --version \
  && command -v codex-code-mode-host \
  && test -x /usr/local/bin/codex-code-mode-host \
  && codex-code-mode-host --help \
  && command -v node \
  && node --version

COPY run.sh /run.sh
COPY session.sh /usr/local/bin/ha-codex-session
COPY ha-codex-ha /usr/local/bin/ha-codex-ha
COPY tmux.conf /etc/ha-codex-tmux.conf
RUN chmod 0755 /run.sh /usr/local/bin/ha-codex-session /usr/local/bin/ha-codex-ha \
  && mkdir -p /homeassistant /config/codex

WORKDIR /homeassistant

HEALTHCHECK --interval=30s --timeout=10s --start-period=20s --retries=3 \
  CMD curl --fail --silent http://127.0.0.1:7681/ >/dev/null || exit 1

CMD [ "/run.sh" ]
