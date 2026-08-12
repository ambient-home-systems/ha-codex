#!/usr/bin/with-contenv bashio
set -euo pipefail

readonly CODEX_DATA_DIR="/config/codex"
readonly TERMINAL_INDEX="/tmp/ha-codex-terminal.html"

mkdir -p "${CODEX_DATA_DIR}"
export CODEX_HOME="${CODEX_DATA_DIR}"

FONT_SIZE="$(bashio::config 'terminal_font_size')"
SCROLLBACK="$(bashio::config 'terminal_scrollback')"
THEME="$(bashio::config 'terminal_theme')"
PERSIST="$(bashio::config 'session_persistence')"
PRESERVE_HISTORY="$(bashio::config 'preserve_terminal_history')"
PATCH_COMPATIBILITY_MODE="$(bashio::config 'patch_compatibility_mode')"
MODEL="$(bashio::config 'model')"
HOME_ASSISTANT_CONTROL="$(bashio::config 'home_assistant_control')"
ALLOW_HOME_ASSISTANT_RESTART="$(bashio::config 'allow_home_assistant_restart')"
export HA_CODEX_HOME_ASSISTANT_CONTROL="${HOME_ASSISTANT_CONTROL}"
export HA_CODEX_ALLOW_HOME_ASSISTANT_RESTART="${ALLOW_HOME_ASSISTANT_RESTART}"
export HA_CODEX_PATCH_COMPATIBILITY_MODE="${PATCH_COMPATIBILITY_MODE}"

TERMINAL_MODE="fullscreen"
if [ "${PRESERVE_HISTORY}" = "true" ]; then
  TERMINAL_MODE="inline"
fi

# This name must stay independent of login-menu revisions so a sign-in change
# never replaces a user's persistent terminal session.
readonly SESSION_NAME="home-assistant-codex-${MODEL}-${TERMINAL_MODE}-device-code-v2"
TTYD_INDEX_ARGS=()

if [ "${PERSIST}" = "true" ]; then
  # tmux preserves the live Codex process across Home Assistant navigation.
  # Its configuration is loaded before the server starts so mouse scrolling
  # enters copy mode rather than recalling commands at the prompt.
  COMMAND="tmux -f /etc/ha-codex-tmux.conf set-option -g history-limit ${SCROLLBACK}; tmux -f /etc/ha-codex-tmux.conf new-session -A -s ${SESSION_NAME} '/usr/local/bin/ha-codex-session ${MODEL} ${TERMINAL_MODE}; exec bash -l'"
else
  COMMAND="exec /usr/local/bin/ha-codex-session ${MODEL} ${TERMINAL_MODE}"
fi

bashio::log.info "Starting HA Codex."
bashio::log.info "Using Codex model: ${MODEL}."
bashio::log.info "Terminal history mode: ${TERMINAL_MODE}."
bashio::log.info "First-time sign-in uses the HA Codex device-code method by default."
if [ "${PATCH_COMPATIBILITY_MODE}" = "true" ]; then
  bashio::log.info "Patch compatibility mode: true (new Codex sessions start with sandbox danger-full-access)."
else
  bashio::log.info "Patch compatibility mode: false (Codex uses its Bubblewrap sandbox, which apply_patch cannot use on Home Assistant OS)."
fi
bashio::log.info "Sandbox mode applies when a Codex session starts; restart the add-on after changing it so a fresh session takes effect."
bashio::log.info "Home Assistant control actions: ${HOME_ASSISTANT_CONTROL}; Core restart: ${ALLOW_HOME_ASSISTANT_RESTART}."

# ttyd bundles its browser client in its executable.  Extract its matching
# page, then add one deliberately small scroll rail.  The sed replacement
# contains no ampersands: in sed replacements an ampersand expands to the
# matched HTML, which previously corrupted the injected markup and scripts.
GZIP_OFFSET="$(LC_ALL=C grep -abo $'\x1f\x8b\x08' /usr/local/bin/ttyd | head -n 1 | LC_ALL=C cut -d: -f1 || true)"
if [ -n "${GZIP_OFFSET}" ]; then
  dd if=/usr/local/bin/ttyd bs=1 skip="${GZIP_OFFSET}" 2>/dev/null | gzip -dc 2>/dev/null > "${TERMINAL_INDEX}" || true

  if [ -s "${TERMINAL_INDEX}" ] && grep -q '</html>' "${TERMINAL_INDEX}"; then
    sed -i "s/fontSize:13,/scrollback:${SCROLLBACK},fontSize:13,/" "${TERMINAL_INDEX}"
    sed -i 's@</head>@<style id="ha-codex-history-rail-style">#terminal-container{padding-right:34px!important}.ha-codex-history-rail{position:fixed;z-index:1000;top:6px;right:4px;bottom:6px;width:28px;display:flex;flex-direction:column;gap:4px;padding:2px;box-sizing:border-box;background:#20242d;border-left:1px solid #63543a}.ha-codex-history-rail button{height:25px;padding:0;border:1px solid #6b5734;border-radius:5px;background:#3a3225;color:#f6c66f;font:700 17px/1 sans-serif}.ha-codex-history-track{position:relative;flex:1;min-height:44px;border-radius:6px;background:#15191f;touch-action:none;cursor:ns-resize}.ha-codex-history-thumb{position:absolute;left:3px;right:3px;top:3px;height:48px;border-radius:5px;background:#e6a23c;box-shadow:inset 0 0 0 1px rgba(255,255,255,.4)}</style></head>@' "${TERMINAL_INDEX}"
    sed -i 's@</body>@<script id="ha-codex-history-rail-script">(()=>{let retry;const start=()=>{const term=window.term;if(!term){return}if(document.getElementById("ha-codex-history-rail")){clearInterval(retry);return}const rail=document.createElement("div");const up=document.createElement("button");const down=document.createElement("button");const track=document.createElement("div");const thumb=document.createElement("div");rail.id="ha-codex-history-rail";rail.className="ha-codex-history-rail";up.type="button";down.type="button";up.textContent="↑";down.textContent="↓";up.setAttribute("aria-label","Scroll terminal history up");down.setAttribute("aria-label","Scroll terminal history down");track.className="ha-codex-history-track";thumb.className="ha-codex-history-thumb";track.appendChild(thumb);rail.append(up,track,down);document.body.appendChild(rail);const send=delta=>{const el=term.element;if(el){el.dispatchEvent(new WheelEvent("wheel",{bubbles:true,cancelable:true,deltaY:delta}))}};const buffer=()=>term.buffer.active;const sync=()=>{const b=buffer();const range=b.baseY;const h=track.clientHeight;const th=Math.max(28,Math.min(h,h*((term.rows||1)/Math.max(b.length,1))));const space=Math.max(0,h-th);thumb.style.height=th+"px";thumb.style.transform="translateY("+(range?space*b.viewportY/range:0)+"px)"};const move=y=>{const b=buffer();const r=track.getBoundingClientRect();const f=Math.max(0,Math.min(1,(y-r.top)/r.height));if(b.baseY){term.scrollLines(Math.round(f*b.baseY)-b.viewportY)}else{send(f<.5?-360:360)}sync()};up.addEventListener("click",()=>{if(buffer().baseY){term.scrollLines(-20)}else{send(-360)}sync()});down.addEventListener("click",()=>{if(buffer().baseY){term.scrollLines(20)}else{send(360)}sync()});let drag=false;track.addEventListener("pointerdown",e=>{drag=true;track.setPointerCapture(e.pointerId);move(e.clientY);e.preventDefault()});track.addEventListener("pointermove",e=>{if(drag){move(e.clientY)}});track.addEventListener("pointerup",()=>{drag=false});track.addEventListener("pointercancel",()=>{drag=false});term.onScroll(sync);window.addEventListener("resize",sync);setInterval(sync,250);sync();clearInterval(retry)};retry=setInterval(start,100);start()})();</script></body>@' "${TERMINAL_INDEX}"
    TTYD_INDEX_ARGS=(--index "${TERMINAL_INDEX}")
    bashio::log.info "Enabled terminal history rail."
  else
    bashio::log.warning "Could not prepare the terminal history rail; using ttyd's standard page."
  fi
else
  bashio::log.warning "Could not locate ttyd's browser client; using ttyd's standard page."
fi

exec /usr/local/bin/ttyd \
  --writable \
  --port 7681 \
  --terminal-type xterm-256color \
  --client-option "fontSize=${FONT_SIZE}" \
  --client-option "scrollback=${SCROLLBACK}" \
  --client-option "theme=${THEME}" \
  "${TTYD_INDEX_ARGS[@]}" \
  bash -lc "${COMMAND}"
