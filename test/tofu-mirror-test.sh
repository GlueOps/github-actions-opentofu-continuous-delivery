#!/usr/bin/env bash
# Unit tests for scripts/tofu-mirror.sh. Usage: bash test/tofu-mirror-test.sh
set -u
script="$(cd "$(dirname "$0")/.." && pwd)/scripts/tofu-mirror.sh"
rt=$(mktemp -d); trap 'rm -rf "$rt"' EXIT
H=$rt/_github_home; mkdir -p "$H"
run() { MIRROR=$1 RUNNER_TEMP=$rt HOME=$rt/caller bash "$script" "${@:2}"; }
fail=0
check() { local d=$1; shift; if "$@"; then echo "PASS $d"; else echo "FAIL $d"; fail=1; fi; }
lacks() { ! grep -q "$@"; }
gitcfg() { git config -f "$H/.gitconfig" "$@"; }
# A rejected value must warn, exit 0 and leave no mirror configured.
rejected() {
  local out rc=0
  out=$(run "$1" 2>&1) || rc=$?
  [ "$rc" -eq 0 ] && grep -q '::warning::' <<<"$out" && lacks tofu-mirror "$H/.terraformrc" "$H/.gitconfig"
}

printf '[user]\n    name = keep-me\n' > "$H/.gitconfig"
printf 'plugin_cache_dir = "/keep-me"\n' > "$H/.terraformrc"
run "https://mirror.example.com///" >/dev/null
check "on: host block for registry.opentofu.org, trailing slashes stripped" \
  grep -q '"providers.v1" = "https://mirror.example.com/repository/tofu/registry.opentofu.org/v1/providers/"' "$H/.terraformrc"
check "on: host block for registry.terraform.io keeps modules.v1 upstream" \
  grep -q '"modules.v1"   = "https://registry.terraform.io/v1/modules/"' "$H/.terraformrc"
check "on: git rewrite parses with git" \
  test "$(gitcfg --get url.https://mirror.example.com/repository/git/github.com/.insteadof)" = https://github.com/
check "on: existing .gitconfig and .terraformrc content kept" \
  bash -c '[ "$(git config -f "$1/.gitconfig" user.name)" = keep-me ] && grep -q /keep-me "$1/.terraformrc"' _ "$H"
check "on: caller's own HOME untouched" test ! -e "$rt/caller"
run "https://mirror.example.com" >/dev/null; run "https://mirror.example.com" >/dev/null
check "repeat: exactly one section in each file" \
  test "$(grep -c '^# BEGIN tofu-mirror' "$H/.terraformrc")$(grep -c '^# BEGIN tofu-mirror' "$H/.gitconfig")" = 11
out=$(run "repo.example.com" 2>&1)
check "invalid: warning does not echo the value" lacks repo.example.com <<<"$out"
run "https://mirror.example.com" >/dev/null
check "invalid: warns, exits 0, removes the earlier configuration" rejected "repo.example.com"
run "https://mirror.example.com" >/dev/null
check "newline injection: rejected the same way" rejected "$(printf 'https://a.example.com\nNODE_OPTIONS=--require=/x')"
run "https://mirror.example.com" >/dev/null
check "quote injection: rejected the same way" rejected 'https://a.example.com/"; evil'
run "http://localhost:8080/path" >/dev/null
check "http with port and path accepted" grep -q 'http://localhost:8080/path/repository/tofu' "$H/.terraformrc"
run "off" >/dev/null
check "off: sections removed, user config kept" \
  bash -c '! grep -q tofu-mirror "$1/.terraformrc" "$1/.gitconfig" && [ "$(git config -f "$1/.gitconfig" user.name)" = keep-me ] && grep -q /keep-me "$1/.terraformrc"' _ "$H"
run "https://mirror.example.com" >/dev/null
out=$(run "https://mirror.example.com" --remove 2>&1)
check "--remove: sections removed silently, user config kept" \
  bash -c '[ -z "$2" ] && ! grep -q tofu-mirror "$1/.terraformrc" "$1/.gitconfig" && grep -q /keep-me "$1/.terraformrc"' _ "$H" "$out"
check "empty: exits 0" run ""
exit $fail
