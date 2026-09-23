#!/usr/bin/env bash
# Publish the GitHub Release for one HA Codex version, or fill in its notes.
#
# VERSION defaults to the version in config.yaml. The tag goes on the commit
# that first set config.yaml to that version, and the notes come from that
# version's CHANGELOG section. A release that already has notes is left alone;
# one with empty notes gets them filled in. An existing tag on a different
# commit is an error, never moved.
set -euo pipefail

readonly CONFIG="home_assistant_codex_app/config.yaml"
readonly CHANGELOG="home_assistant_codex_app/CHANGELOG.md"

read_version() {
  sed -n 's/^version: "\(.*\)"$/\1/p'
}

current="$(read_version < "${CONFIG}")"
version="${VERSION:-${current}}"
if ! [[ "${version}" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
  echo "::error::Version must look like 1.2.3, got '${version}'."
  exit 1
fi
tag="v${version}"

commit=""
for candidate in $(git rev-list --reverse HEAD -- "${CONFIG}"); do
  if [ "$(git show "${candidate}:${CONFIG}" | read_version)" = "${version}" ]; then
    commit="${candidate}"
    break
  fi
done
if [ -z "${commit}" ]; then
  echo "::error::No commit sets ${CONFIG} to version ${version}."
  exit 1
fi

notes="$(awk -v heading="## ${version}" '
  $0 == heading { found = 1; next }
  found && /^## / { exit }
  found { print }
' "${CHANGELOG}" | sed -e '/./,$!d')"
if [ -z "${notes}" ]; then
  echo "::error::${CHANGELOG} has no notes under '## ${version}'."
  exit 1
fi

if tag_commit="$(git rev-parse -q --verify "refs/tags/${tag}^{commit}")"; then
  if [ "${tag_commit}" != "${commit}" ]; then
    echo "::error::Tag ${tag} points at ${tag_commit}, but version ${version} was set in ${commit}. Fix the tag by hand."
    exit 1
  fi
fi

echo "Version ${version}: ${tag} on $(git log -1 --format='%h %s' "${commit}")"

if body="$(gh release view "${tag}" --json body --jq .body 2>/dev/null)"; then
  if [ -n "$(printf '%s' "${body}" | tr -d '[:space:]')" ]; then
    echo "Release ${tag} already exists with notes; leaving it unchanged."
    exit 0
  fi
  printf '%s\n' "${notes}" | gh release edit "${tag}" --notes-file -
  echo "Filled in the empty notes of release ${tag}."
  exit 0
fi

# Only the version in config.yaml is marked latest, so backfilling an older
# release never takes the badge away from the current one.
latest="false"
if [ "${version}" = "${current}" ]; then
  latest="true"
fi

printf '%s\n' "${notes}" | gh release create "${tag}" \
  --target "${commit}" \
  --title "HA Codex ${version}" \
  --notes-file - \
  --latest="${latest}"
echo "Published release ${tag} (latest: ${latest})."
