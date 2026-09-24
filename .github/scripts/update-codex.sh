#!/usr/bin/env bash
# Check for a newer stable Codex CLI release and, when one exists, update the
# add-on to it: the CODEX_VERSION pin in build.yaml, a patch bump of the add-on
# version in config.yaml, and a new CHANGELOG section. Nothing is committed here.
#
# A release counts only when it is published (not a draft or prerelease), its
# tag is a plain rust-vX.Y.Z, and it already has both Linux musl archives the
# Dockerfile downloads, since assets can be uploaded after a release appears.
#
# Writes update=true|false, and on an update codex_version, previous_version,
# and addon_version, to GITHUB_OUTPUT when it is set.
set -euo pipefail

readonly BUILD="home_assistant_codex_app/build.yaml"
readonly CONFIG="home_assistant_codex_app/config.yaml"
readonly CHANGELOG="home_assistant_codex_app/CHANGELOG.md"
readonly OUTPUT="${GITHUB_OUTPUT:-/dev/null}"

current="$(sed -n 's/^  CODEX_VERSION: "\(.*\)"$/\1/p' "${BUILD}")"
addon_current="$(sed -n 's/^version: "\(.*\)"$/\1/p' "${CONFIG}")"
if ! [[ "${current}" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] || ! [[ "${addon_current}" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "::error::Could not read CODEX_VERSION from ${BUILD} or version from ${CONFIG}."
  exit 1
fi

latest="$(gh api 'repos/openai/codex/releases?per_page=50' --jq '
  .[]
  | select((.draft | not) and (.prerelease | not))
  | select(.tag_name | test("^rust-v[0-9]+\\.[0-9]+\\.[0-9]+$"))
  | select([.assets[].name] | index("codex-x86_64-unknown-linux-musl.tar.gz"))
  | select([.assets[].name] | index("codex-code-mode-host-x86_64-unknown-linux-musl.tar.gz"))
  | .tag_name | ltrimstr("rust-v")
' | sort -V | tail -n 1)"
if [ -z "${latest}" ]; then
  echo "::error::Found no stable Codex release with the Linux musl archives."
  exit 1
fi

newest="$(printf '%s\n%s\n' "${current}" "${latest}" | sort -V | tail -n 1)"
if [ "${latest}" = "${current}" ] || [ "${newest}" != "${latest}" ]; then
  echo "Codex ${current} is up to date (latest stable release: ${latest})."
  echo "update=false" >> "${OUTPUT}"
  exit 0
fi

IFS=. read -r major minor patch <<< "${addon_current}"
addon_next="${major}.${minor}.$((patch + 1))"

sed -i "s/^  CODEX_VERSION: \"${current}\"$/  CODEX_VERSION: \"${latest}\"/" "${BUILD}"
sed -i "s/^version: \"${addon_current}\"$/version: \"${addon_next}\"/" "${CONFIG}"

entry="$(cat <<EOF
## ${addon_next}

- Updated the pinned Codex CLI from ${current} to ${latest}, including the version-matched \`codex-code-mode-host\` artifact. See the [Codex ${latest} release notes](https://github.com/openai/codex/releases/tag/rust-v${latest}) for what changed.
- Released automatically after the amd64 build and smoke test passed. Model choices and settings are unchanged.
EOF
)"
changelog_updated="$(mktemp)"
ENTRY="${entry}" awk '
  !done && /^## / { print ENVIRON["ENTRY"]; print ""; done = 1 }
  { print }
' "${CHANGELOG}" > "${changelog_updated}"
cat "${changelog_updated}" > "${CHANGELOG}"
rm -f "${changelog_updated}"

if ! grep -qx "  CODEX_VERSION: \"${latest}\"" "${BUILD}" \
  || ! grep -qx "version: \"${addon_next}\"" "${CONFIG}" \
  || ! grep -qx "## ${addon_next}" "${CHANGELOG}"; then
  echo "::error::Failed to apply the Codex ${latest} update."
  exit 1
fi

echo "Updating Codex ${current} -> ${latest}; add-on ${addon_current} -> ${addon_next}."
{
  echo "update=true"
  echo "codex_version=${latest}"
  echo "previous_version=${current}"
  echo "addon_version=${addon_next}"
} >> "${OUTPUT}"
