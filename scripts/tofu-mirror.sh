#!/usr/bin/env bash
# Points this action's OpenTofu steps at a GlueOps tofu-cache mirror ($MIRROR), or
# removes that configuration (empty, "off", invalid, or `--remove` when the action
# ends). It lives in $RUNNER_TEMP/_github_home, the HOME of the dflook containers;
# dflook keeps an existing .terraformrc there and only appends credentials to it.
set -euo pipefail
MIRROR=${MIRROR:-}
home="$RUNNER_TEMP/_github_home"
mkdir -p "$home"

# Replaces this action's section of a config file, or just removes it if $2 is empty.
section() {
  touch "$1"
  awk '/^# BEGIN tofu-mirror$/ {skip=1} !skip {print} /^# END tofu-mirror$/ {skip=0}' "$1" > "$1.tmp"
  if [ -n "$2" ]; then printf '# BEGIN tofu-mirror\n%s\n# END tofu-mirror\n' "$2" >> "$1.tmp"; fi
  cat "$1.tmp" > "$1"
  rm -f "$1.tmp"
}

while [ "${MIRROR%/}" != "$MIRROR" ]; do MIRROR=${MIRROR%/}; done
# Strict, so the value can't break the HCL or git config it is written into.
valid='^https?://[A-Za-z0-9.-]+(:[0-9]{1,5})?(/[A-Za-z0-9._~/-]*)?$'

if [ "${1:-}" = --remove ]; then
  :
elif [ -z "$MIRROR" ] || [ "$MIRROR" = off ]; then
  echo "tofu mirror: off"
elif [[ $MIRROR =~ $valid ]]; then
  echo "tofu mirror: on ($MIRROR)"
  # A host block replaces service discovery for that registry, so modules.v1 is listed too.
  rc=""
  for reg in registry.opentofu.org registry.terraform.io; do
    rc+="host \"$reg\" {
  services = {
    \"providers.v1\" = \"$MIRROR/repository/tofu/$reg/v1/providers/\"
    \"modules.v1\"   = \"https://$reg/v1/modules/\"
  }
}
"
  done
  section "$home/.terraformrc" "$rc"
  section "$home/.gitconfig" "[url \"$MIRROR/repository/git/github.com/\"]
    insteadOf = https://github.com/"
  exit 0
else
  echo "::warning::tofu mirror: tofu_mirror_url / TOFU_MIRROR_URL is not an http(s) base URL; running without the mirror"
fi
section "$home/.terraformrc" ""
section "$home/.gitconfig" ""
