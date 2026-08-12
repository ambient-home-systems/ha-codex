#!/usr/bin/env bash
set -u

readonly MODEL="$1"
readonly TERMINAL_MODE="$2"
readonly HA_CODEX_INSTRUCTIONS='Home Assistant control is available only through the ha-codex-ha helper. For a requested configuration check, reload, or restart, explain the intended action and use ha-codex-ha rather than direct curl, ha, hass, systemctl, Docker, or SUPERVISOR_TOKEN access. Ask for command approval before any reload or restart. Run ha-codex-ha check before a Core restart; the helper enforces this too. Use ha-codex-ha --help to see the allowlisted actions. Dashboard configuration may require a browser refresh; dashboard-resources only reloads Lovelace resources.'
readonly HA_CODEX_CONFIG_OVERRIDE="developer_instructions=\"${HA_CODEX_INSTRUCTIONS}\""

cd /homeassistant

if ! codex login status >/dev/null 2>&1; then
  clear
  printf '%s\n' \
    'HA Codex sign in' \
    '' \
    '1. Sign in with Device Code (Preferred Method)' \
    '   Sign in from another device with a secure, one-time code.' \
    '' \
    '2. Provide your own API key' \
    '   Pay for usage through an OpenAI Platform account.' \
    ''

  while true; do
    printf 'Select 1 or 2: '
    IFS= read -r choice || exit 1

    case "${choice}" in
      1)
        if codex login --device-auth; then
          break
        fi
        printf '\nDevice-code sign-in did not complete. Please try again.\n\n'
        ;;
      2)
        printf 'Paste your OpenAI API key (input is hidden): '
        IFS= read -r -s api_key || exit 1
        printf '\n'

        if [ -z "${api_key}" ]; then
          printf 'An API key is required. Please try again.\n\n'
        elif printf '%s' "${api_key}" | codex login --with-api-key; then
          unset api_key
          break
        else
          unset api_key
          printf '\nAPI-key sign-in did not complete. Please try again.\n\n'
        fi
        ;;
      *)
        printf 'Please enter 1 or 2.\n\n'
        ;;
    esac
  done
fi

CODEX_ARGS=(--config "${HA_CODEX_CONFIG_OVERRIDE}")

# Home Assistant OS does not allow the nested unprivileged user namespace that
# Codex's Bubblewrap sandbox needs. Without it, apply_patch fails while reading
# the target file ("bwrap: Failed to make / slave: Permission denied") because
# its filesystem-verification helper runs under Bubblewrap. The add-on is
# already the security boundary: it has no host, Docker, or Supervisor-management
# access. Start Codex in full-access so patches use that container boundary
# instead of Bubblewrap, while leaving Codex's command approval policy untouched.
#
# This applies only to a newly started session. Codex keeps the sandbox mode it
# launched with, so a session that started before this mode was enabled, or one
# switched with /approvals, stays in workspace-write until Codex restarts. When
# that happens, restart the add-on or choose Full Access in /approvals.
# The setting remains available for troubleshooting.
if [ "${HA_CODEX_PATCH_COMPATIBILITY_MODE:-true}" = "true" ]; then
  CODEX_ARGS+=(--sandbox danger-full-access)
fi

CODEX_ARGS+=(--model "${MODEL}")

if [ "${TERMINAL_MODE}" = "inline" ]; then
  exec codex --no-alt-screen "${CODEX_ARGS[@]}"
fi

exec codex "${CODEX_ARGS[@]}"
