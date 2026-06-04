#!/usr/bin/env bash
# install-skills.sh — discover terraform-modules usages in a downstream project and install
# matching Claude Code skills (.claude/skills/<module>/) pinned to the same ref used in code.
#
# Usage:
#   bash install-skills.sh [PROJECT_DIR]
#
# Scans PROJECT_DIR (default: cwd) for `module {}` blocks sourcing this repo, e.g.:
#   source = "git::https://github.com/shangkuei/terraform-modules.git//<module>?ref=<tag>"
# Then for each unique (module, ref) it caches a clone at $TF_SKILL_CACHE/<ref> and
# symlinks .claude/skills/<module> -> <cache>/.claude/skills/<module>.
#
# Re-runs are idempotent. Stale symlinks pointing into the cache (modules no longer
# referenced) are removed; symlinks/files pointing elsewhere are left untouched.
#
# Environment:
#   TF_SKILL_REPO   repo URL (default: https://github.com/shangkuei/terraform-modules.git)
#   TF_SKILL_CACHE  cache directory (default: $HOME/.cache/terraform-module-skills)
#   SKILLS_DIR      install directory relative to PROJECT_DIR (default: .claude/skills)

set -euo pipefail

PROJECT_DIR="${1:-$PWD}"
REPO_URL="${TF_SKILL_REPO:-https://github.com/shangkuei/terraform-modules.git}"
CACHE_DIR="${TF_SKILL_CACHE:-$HOME/.cache/terraform-module-skills}"
SKILLS_DIR_REL="${SKILLS_DIR:-.claude/skills}"
REPO_PATH_PATTERN='github.com[:/]shangkuei/terraform-modules'

log()  { printf '%s\n' "$*" >&2; }
warn() { printf 'warn: %s\n' "$*" >&2; }
die()  { printf 'error: %s\n' "$*" >&2; exit 1; }

[ -d "$PROJECT_DIR" ] || die "PROJECT_DIR not found: $PROJECT_DIR"
cd "$PROJECT_DIR"

# 1. Discover unique module-source URLs pointing at our repo.
source_urls=()
while IFS= read -r line; do
  [ -n "$line" ] && source_urls+=("$line")
done < <(
  find . -type f \( -name '*.tf' -o -name '*.tf.json' \) \
    -not -path './.terraform/*' -not -path '*/.terraform/*' \
    -print0 2>/dev/null \
  | xargs -0 grep -hoE 'source[[:space:]]*=[[:space:]]*"git::[^"]+"' 2>/dev/null \
  | grep -E "$REPO_PATH_PATTERN" \
  | sed -E 's/.*"git::([^"]+)".*/\1/' \
  | sort -u
)

if [ "${#source_urls[@]}" -eq 0 ]; then
  log "no terraform-modules sources found in $PROJECT_DIR"
  exit 0
fi

# 2. Parse each URL into (module, ref) pairs.
PAIRS="$(mktemp -t install-skills.XXXXXX)"
RESOLVED="$(mktemp -t install-skills-resolved.XXXXXX)"
trap 'rm -f "$PAIRS" "$RESOLVED"' EXIT

for url in "${source_urls[@]}"; do
  if [[ "$url" != *.git//* ]]; then
    warn "missing module subpath, skipping: $url"
    continue
  fi
  rest="${url#*.git//}"
  module="${rest%%\?*}"
  module="${module%%/*}"

  if [[ "$url" != *\?*ref=* ]]; then
    warn "missing ?ref=<tag>, skipping (pin the version): $url"
    continue
  fi
  query="${url#*\?}"
  ref=""
  IFS='&' read -r -a parts <<< "$query"
  for kv in "${parts[@]}"; do
    if [[ "$kv" == ref=* ]]; then
      ref="${kv#ref=}"
      break
    fi
  done
  [ -n "$ref" ] || { warn "could not parse ref from: $url"; continue; }

  printf '%s\t%s\n' "$module" "$ref" >> "$PAIRS"
done

if [ ! -s "$PAIRS" ]; then
  log "no usable module sources after parsing"
  exit 0
fi

# 3. Resolve conflicts: if a module is pinned at multiple refs, keep the latest (semver-ordered)
#    and emit a notice naming the files that need to be upgraded.
for m in $(cut -f1 "$PAIRS" | sort -u); do
  refs="$(awk -F'\t' -v m="$m" '$1==m {print $2}' "$PAIRS" | sort -u)"
  count="$(printf '%s\n' "$refs" | wc -l | tr -d ' ')"
  if [ "$count" -le 1 ]; then
    printf '%s\t%s\n' "$m" "$refs" >> "$RESOLVED"
    continue
  fi
  latest="$(printf '%s\n' "$refs" | sort -V | tail -1)"
  log "notice: module '$m' is pinned at multiple refs — using latest ($latest); older blocks need upgrade:"
  for r in $refs; do
    [ "$r" = "$latest" ] && continue
    files="$(find . -type f \( -name '*.tf' -o -name '*.tf.json' \) \
              -not -path './.terraform/*' -not -path '*/.terraform/*' \
              -exec grep -lF "terraform-modules.git//${m}?ref=${r}" {} + 2>/dev/null \
            | sort -u | paste -sd, -)"
    if [ -n "$files" ]; then
      log "  - $r → $latest in: $files"
    else
      log "  - $r → $latest"
    fi
  done
  printf '%s\t%s\n' "$m" "$latest" >> "$RESOLVED"
done

# 4. Cache the repo at each unique ref. Returns non-zero if the ref can't be fetched.
ensure_cache() {
  local ref="$1"
  local ref_safe="${ref//\//__}"
  local cache="$CACHE_DIR/$ref_safe"
  CACHE_PATH="$cache"
  if [ -d "$cache/.git" ]; then
    return 0
  fi
  mkdir -p "$CACHE_DIR"
  if git clone --depth=1 --branch="$ref" --quiet "$REPO_URL" "$cache" 2>/dev/null; then
    return 0
  fi
  # Shallow-clone failed (commit SHA, or ref doesn't exist). Fall back to a full clone + checkout.
  rm -rf "$cache"
  if ! git clone --quiet "$REPO_URL" "$cache" 2>/dev/null; then
    return 1
  fi
  if ! git -C "$cache" checkout --quiet "$ref" 2>/dev/null; then
    rm -rf "$cache"
    return 1
  fi
}

mkdir -p "$SKILLS_DIR_REL"

# 5. Install (symlink) skills for each (module, ref).
installed_names=()
while IFS=$'\t' read -r module ref; do
  if ! ensure_cache "$ref"; then
    warn "could not fetch ref '$ref' from $REPO_URL — skipping module '$module'"
    continue
  fi
  src="$CACHE_PATH/$SKILLS_DIR_REL/$module"
  if [ ! -d "$src" ]; then
    warn "no SKILL.md for module '$module' at $ref (missing $src) -- skipping"
    continue
  fi
  dst="$SKILLS_DIR_REL/$module"
  if [ -L "$dst" ] || [ -e "$dst" ]; then
    rm -rf "$dst"
  fi
  src_abs="$(cd "$(dirname "$src")" && pwd -P)/$(basename "$src")"
  ln -s "$src_abs" "$dst"
  installed_names+=("$module")
  log "installed: $dst -> $src_abs  ($ref)"
done < <(sort -u "$RESOLVED")

# 6. Clean up stale symlinks that point into our cache but aren't currently referenced.
if [ -d "$SKILLS_DIR_REL" ]; then
  for path in "$SKILLS_DIR_REL"/*; do
    [ -L "$path" ] || continue
    target="$(readlink "$path" 2>/dev/null || true)"
    case "$target" in
      "$CACHE_DIR"/*)
        name="$(basename "$path")"
        keep=0
        for n in "${installed_names[@]}"; do
          [ "$n" = "$name" ] && { keep=1; break; }
        done
        if [ "$keep" -eq 0 ]; then
          log "removed stale skill: $path"
          rm -f "$path"
        fi
        ;;
    esac
  done
fi

if [ "${#installed_names[@]}" -eq 0 ]; then
  log "no skills installed"
fi
