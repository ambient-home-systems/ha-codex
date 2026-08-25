ARG BUILD_FROM
FROM ${BUILD_FROM}

ARG TTYD_VERSION
ARG TRZSZ_VERSION

ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    TERM=xterm-256color

# Codex itself is installed with OpenAI's Linux installer. ttyd provides the
# terminal that Home Assistant exposes through Ingress. trzsz supplies the
# trz/tsz commands; ttyd's bundled client turns them into a browser file picker
# so files can be attached to (and downloaded from) the terminal.
RUN apk add --no-cache \
      bash \
      bubblewrap \
      ca-certificates \
      curl \
      git \
      grep \
      gzip \
      jq \
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
  && curl -fsSL https://chatgpt.com/codex/install.sh | CODEX_HOME=/opt/codex CODEX_INSTALL_DIR=/usr/local/bin CODEX_NON_INTERACTIVE=1 sh \
  && codex --version

COPY run.sh /run.sh
COPY session.sh /usr/local/bin/ha-codex-session
COPY ha-codex-ha /usr/local/bin/ha-codex-ha
COPY tmux.conf /etc/ha-codex-tmux.conf
RUN chmod 0755 /run.sh /usr/local/bin/ha-codex-session /usr/local/bin/ha-codex-ha \
  && mkdir -p /homeassistant /config/codex /opt/codex

WORKDIR /homeassistant

HEALTHCHECK --interval=30s --timeout=10s --start-period=20s --retries=3 \
  CMD curl --fail --silent http://127.0.0.1:7681/ >/dev/null || exit 1

CMD [ "/run.sh" ]
