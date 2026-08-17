#!/usr/bin/env bash
#
# Promote a chart from the upstream development repository into this one and open
# a draft release PR.
#
# The upstream chart is copied verbatim; the only fields rewritten are `version`
# and `appVersion` in Chart.yaml. Everything else (templates, values, README,
# vendored subcharts) is taken as-is, and files removed upstream are removed here.
#
# All work happens in a throwaway git worktree, so the current checkout is never
# touched and a dirty working tree is fine.
#
# Required environment:
#   SOURCE_REPO   owner/name of the upstream repository
#   SOURCE_TOKEN  token with read access to it (falls back to GH_TOKEN /
#                 GITHUB_TOKEN, then to the local git credentials)
#
# Usage:
#   scripts/promote-chart.sh --chart idv --app-version 3.10.0 [options]
#
#   --chart NAME           docreader | faceapi | idv          (required)
#   --app-version VERSION  released image tag                 (required)
#   --chart-version VER    override; default is the upstream chart version
#   --source-ref REF       upstream ref to promote from       (default: main)
#   --since REF            upstream ref to build the changelog from; default is
#                          detected by matching the currently published content
#   --dry-run              print everything, change nothing
#   --no-pr                create the branch and commit locally, but do not push
#   -h, --help             this text

set -euo pipefail

readonly PROMOTABLE_CHARTS=("docreader" "faceapi" "idv")
readonly ANCHOR_SCAN_DEPTH=200

chart=""
app_version=""
chart_version=""
source_ref="main"
since_ref=""
dry_run=false
open_pr=true

log()  { printf '%s\n' "$*" >&2; }
step() { printf '\n▸ %s\n' "$*" >&2; }
die()  { printf '\nerror: %s\n' "$*" >&2; exit 1; }

usage() { sed -n '3,/^set -euo/p' "$0" | sed 's/^# \{0,1\}//;$d'; }

# --- arguments ---

while [[ $# -gt 0 ]]; do
  case "$1" in
    --chart)         chart="${2:-}"; shift 2 ;;
    --app-version)   app_version="${2:-}"; shift 2 ;;
    --chart-version) chart_version="${2:-}"; shift 2 ;;
    --source-ref)    source_ref="${2:-}"; shift 2 ;;
    --since)         since_ref="${2:-}"; shift 2 ;;
    --dry-run)       dry_run=true; shift ;;
    --no-pr)         open_pr=false; shift ;;
    -h|--help)       usage; exit 0 ;;
    *)               die "unknown argument: $1 (try --help)" ;;
  esac
done

# --- preflight ---

display_name() {
  case "$1" in
    docreader) printf 'Docreader' ;;
    faceapi)   printf 'FaceAPI' ;;
    idv)       printf 'IDV' ;;
    *)         printf '%s' "$1" ;;
  esac
}

is_promotable() {
  local candidate="$1" allowed
  for allowed in "${PROMOTABLE_CHARTS[@]}"; do
    [[ "$candidate" == "$allowed" ]] && return 0
  done
  return 1
}

[[ -n "$chart" ]] || die "--chart is required (one of: ${PROMOTABLE_CHARTS[*]})"
is_promotable "$chart" || die "chart '$chart' is not promotable. Allowed: ${PROMOTABLE_CHARTS[*]}"

[[ -n "$app_version" ]] || die "--app-version is required"
case "$app_version" in
  nightly*|develop*)
    die "--app-version '$app_version' is a development tag. Pass the released image tag." ;;
esac

for tool in git helm rsync; do
  command -v "$tool" >/dev/null || die "required tool not found: $tool"
done
if [[ "$dry_run" == false && "$open_pr" == true ]]; then
  command -v gh >/dev/null || die "required tool not found: gh (or pass --no-pr)"
fi

[[ -n "${SOURCE_REPO:-}" ]] || die "SOURCE_REPO is not set (expected owner/name of the upstream repository)"
source_token="${SOURCE_TOKEN:-${GH_TOKEN:-${GITHUB_TOKEN:-}}}"

repo_root="$(git rev-parse --show-toplevel 2>/dev/null)" || die "not inside a git repository"
cd "$repo_root"
[[ -d charts ]] || die "no charts/ directory in $repo_root — run this from the charts repository"

# --- helpers ---

# Read a top-level scalar from a Chart.yaml, stripping quotes.
chart_field() {
  local file="$1" key="$2"
  grep -m1 "^${key}:" "$file" 2>/dev/null \
    | sed -e "s/^${key}:[[:space:]]*//" -e 's/[[:space:]]*$//' -e 's/^["'\'']//' -e 's/["'\'']$//'
}

# True when $1 is a strictly greater dotted version than $2.
version_gt() {
  local a="$1" b="$2" i n
  local -a A B
  IFS='.' read -r -a A <<<"$a"
  IFS='.' read -r -a B <<<"$b"
  n=$(( ${#A[@]} > ${#B[@]} ? ${#A[@]} : ${#B[@]} ))
  for (( i = 0; i < n; i++ )); do
    local x="${A[i]:-0}" y="${B[i]:-0}"
    x="${x%%[^0-9]*}"; y="${y%%[^0-9]*}"
    x="${x:-0}";       y="${y:-0}"
    (( 10#$x > 10#$y )) && return 0
    (( 10#$x < 10#$y )) && return 1
  done
  return 1
}

# Content fingerprint of a chart at a revision, ignoring Chart.yaml. Git blob
# ids are content hashes, so the same content fingerprints identically in both
# repositories.
fingerprint() {
  local repo="$1" rev="$2" name="$3"
  git -C "$repo" ls-tree -r "$rev" -- "charts/${name}" 2>/dev/null \
    | awk -v pfx="charts/${name}/" '
        { sha = $3; path = $0; sub(/^[^\t]*\t/, "", path); sub("^" pfx, "", path)
          if (path != "Chart.yaml") print path, sha }' \
    | LC_ALL=C sort | shasum | awk '{ print $1 }'
}

top_level_keys() {
  grep -E '^[A-Za-z_][A-Za-z0-9_.-]*:' "$1" 2>/dev/null | cut -d: -f1 | LC_ALL=C sort -u
}

as_list() { # newline separated -> "a, b, c" or an em dash when empty
  local joined
  joined="$(paste -sd, - | sed 's/,/, /g')"
  [[ -n "$joined" ]] && printf '`%s`' "$joined" || printf '—'
}

# --- setup ---

work_root="$(mktemp -d)"
src_dir="$work_root/source"
worktree=""
branch=""
branch_created=false
committed=false

# Leave nothing behind: drop the temporary worktree, and roll back the release
# branch if we created it but never got as far as committing, so a failed run
# can simply be retried.
cleanup() {
  [[ -n "$worktree" && -d "$worktree" ]] && git worktree remove --force "$worktree" 2>/dev/null || true
  if [[ "$branch_created" == true && "$committed" == false && -n "$branch" ]]; then
    git branch -D "$branch" 2>/dev/null || true
  fi
  rm -rf "$work_root"
}
trap cleanup EXIT

step "Fetching origin/main"
git fetch --quiet origin main
git rev-parse --verify --quiet origin/main >/dev/null || die "origin/main not found"

step "Fetching upstream chart source (ref: $source_ref)"
clone_ok=false
if [[ -n "$source_token" ]]; then
  if git clone --quiet --branch "$source_ref" --single-branch \
       "https://x-access-token:${source_token}@github.com/${SOURCE_REPO}.git" "$src_dir" 2>/dev/null; then
    clone_ok=true
  fi
else
  for url in "https://github.com/${SOURCE_REPO}.git" "git@github.com:${SOURCE_REPO}.git"; do
    if git clone --quiet --branch "$source_ref" --single-branch "$url" "$src_dir" 2>/dev/null; then
      clone_ok=true; break
    fi
  done
fi
$clone_ok || die "could not read the upstream repository at ref '$source_ref'.
       Check SOURCE_REPO and that the token or local credentials grant read access."

source_chart_dir="$src_dir/charts/$chart"
[[ -d "$source_chart_dir" ]] || die "chart '$chart' does not exist upstream at ref '$source_ref'"
source_sha="$(git -C "$src_dir" rev-parse HEAD)"

# --- versions ---

step "Resolving versions"
upstream_version="$(chart_field "$source_chart_dir/Chart.yaml" version)"
upstream_app="$(chart_field "$source_chart_dir/Chart.yaml" appVersion)"
[[ -n "$upstream_version" ]] || die "could not read 'version' from the upstream Chart.yaml"

published_version=""
published_app=""
if git cat-file -e "origin/main:charts/$chart/Chart.yaml" 2>/dev/null; then
  published_chart_yaml="$work_root/published-Chart.yaml"
  git show "origin/main:charts/$chart/Chart.yaml" >"$published_chart_yaml"
  published_version="$(chart_field "$published_chart_yaml" version)"
  published_app="$(chart_field "$published_chart_yaml" appVersion)"
fi

new_version="${chart_version:-$upstream_version}"

log "  upstream    ${upstream_version} (appVersion ${upstream_app:-none})"
log "  published   ${published_version:-none} (appVersion ${published_app:-none})"
log "  promoting   ${new_version} (appVersion ${app_version})"

if [[ -n "$published_version" ]] && ! version_gt "$new_version" "$published_version"; then
  die "chart version ${new_version} is not greater than the published ${published_version}.
       CI enforces an increment, so this PR could not pass. Either bump the chart
       version upstream, or pass --chart-version with a higher value."
fi

# --- changelog anchor ---

step "Locating the last promoted upstream commit"
anchor=""
if [[ -n "$since_ref" ]]; then
  anchor="$(git -C "$src_dir" rev-parse --verify "$since_ref^{commit}" 2>/dev/null)" \
    || die "--since '$since_ref' is not a valid upstream revision"
  log "  using --since $since_ref (${anchor:0:8})"
elif [[ -n "$published_version" ]]; then
  published_fp="$(fingerprint "$repo_root" origin/main "$chart")"
  while read -r candidate; do
    [[ -n "$candidate" ]] || continue
    if [[ "$(fingerprint "$src_dir" "$candidate" "$chart")" == "$published_fp" ]]; then
      anchor="$candidate"; break
    fi
  done < <(git -C "$src_dir" log --format='%H' -n "$ANCHOR_SCAN_DEPTH" -- "charts/$chart")
  if [[ -n "$anchor" ]]; then
    log "  matched published content at ${anchor:0:8}"
  else
    log "  no upstream commit matches the published content — changelog will be omitted"
  fi
fi

# --- copy in ---

step "Building the promotion in a temporary worktree"
worktree="$work_root/worktree"
branch="release/${chart}-${new_version}"
if $dry_run; then
  git worktree add --quiet --detach "$worktree" origin/main
else
  git rev-parse --verify --quiet "refs/heads/$branch" >/dev/null \
    && die "branch '$branch' already exists locally — delete it or pick another version"
  git worktree add --quiet -b "$branch" "$worktree" origin/main
  branch_created=true
fi

mkdir -p "$worktree/charts/$chart"
rsync -a --delete --exclude 'test-*.yaml' "$source_chart_dir/" "$worktree/charts/$chart/"

target_chart_yaml="$worktree/charts/$chart/Chart.yaml"
sed -i.bak \
  -e "s|^version:.*|version: ${new_version}|" \
  -e "s|^appVersion:.*|appVersion: ${app_version}|" \
  "$target_chart_yaml"
rm -f "${target_chart_yaml}.bak"

[[ "$(chart_field "$target_chart_yaml" version)" == "$new_version" ]] \
  || die "failed to rewrite 'version' in Chart.yaml"
[[ "$(chart_field "$target_chart_yaml" appVersion)" == "$app_version" ]] \
  || die "failed to rewrite 'appVersion' in Chart.yaml"

if [[ -z "$(git -C "$worktree" status --porcelain -- "charts/$chart")" ]]; then
  die "nothing to promote: the upstream chart at '$source_ref' is already published as-is."
fi

# --- validate ---

step "Validating the promoted chart"
dep_status="$(helm dependency list "$worktree/charts/$chart" 2>/dev/null || true)"
if grep -qiE 'missing|wrong version' <<<"$dep_status"; then
  log "$dep_status"
  die "vendored subchart archives do not satisfy Chart.yaml dependencies"
fi
log "  dependencies ok"

helm lint "$worktree/charts/$chart" >/dev/null || die "helm lint failed"
log "  helm lint ok"

helm template promote "$worktree/charts/$chart" --set licenseSecretName=promote-check \
  >"$work_root/rendered.yaml" || die "helm template failed"
log "  helm template ok ($(grep -c '^kind:' "$work_root/rendered.yaml") resources)"

# --- summary ---

step "Summarising the change"
old_templates="$work_root/old-templates"
new_templates="$work_root/new-templates"
git ls-tree -r --name-only origin/main -- "charts/$chart/templates" 2>/dev/null \
  | sed "s|^charts/${chart}/templates/||" | LC_ALL=C sort >"$old_templates"
( cd "$worktree/charts/$chart/templates" && find . -type f ) \
  | sed 's|^\./||' | LC_ALL=C sort >"$new_templates"

templates_added="$(comm -13 "$old_templates" "$new_templates" | as_list)"
templates_removed="$(comm -23 "$old_templates" "$new_templates" | as_list)"

old_keys="$work_root/old-keys"
new_keys="$work_root/new-keys"
: >"$old_keys"
if git cat-file -e "origin/main:charts/$chart/values.yaml" 2>/dev/null; then
  git show "origin/main:charts/$chart/values.yaml" >"$work_root/old-values.yaml"
  top_level_keys "$work_root/old-values.yaml" >"$old_keys"
fi
top_level_keys "$worktree/charts/$chart/values.yaml" >"$new_keys"

keys_added="$(comm -13 "$old_keys" "$new_keys" | as_list)"
keys_removed="$(comm -23 "$old_keys" "$new_keys" | as_list)"

changelog=""
if [[ -n "$anchor" ]]; then
  changelog="$(git -C "$src_dir" log --format='%s' "${anchor}..${source_sha}" -- "charts/$chart" \
    | sed -E 's/[[:space:]]*\(#[0-9]+\)[[:space:]]*$//' \
    | grep -viE 'bump (the )?(chart )?version|update (the )?(chart )?version' \
    | sed 's/^/- /' || true)"
fi

# --- PR body ---

title="$(display_name "$chart"): Release chart ${new_version} (appVersion ${app_version})"
body_file="$work_root/pr-body.md"

{
  printf '## %s %s\n\n' "$(display_name "$chart")" "$new_version"
  printf '|               | current | this PR |\n'
  printf '|---------------|---------|---------|\n'
  printf '| chart version | %s | %s |\n' "${published_version:-—}" "$new_version"
  printf '| appVersion    | %s | %s |\n' "${published_app:-—}" "$app_version"

  printf '\n### Changes\n'
  if [[ -n "$changelog" ]]; then
    printf '%s\n' "$changelog"
  elif [[ -n "$anchor" ]]; then
    printf 'No chart changes — this release updates the application version only.\n'
  else
    printf 'Not derivable for this release — review the file diff below.\n'
  fi

  printf '\n### values.yaml (top-level keys)\n'
  printf 'Added: %s\n\n' "$keys_added"
  printf 'Removed: %s\n' "$keys_removed"

  printf '\n### templates\n'
  printf 'Added: %s\n\n' "$templates_added"
  printf 'Removed: %s\n' "$templates_removed"

  if [[ "$templates_removed" != '—' || "$keys_removed" != '—' ]]; then
    printf '\n> Removed templates or values keys — confirm this is intended and call it\n'
    printf '> out for upgraders before merging.\n'
  fi

  printf '\n### Pre-flight\n'
  printf 'Dependencies resolved, `helm lint` and `helm template` pass against default values.\n'

  printf '\n### Checklist\n'
  printf -- '- [ ] appVersion `%s` matches the published image tag\n' "$app_version"
  printf -- '- [ ] README parameter tables match values.yaml\n'
  printf -- '- [ ] Renamed or removed values called out for upgraders\n'
  printf -- '- [ ] Mark ready for review\n'
} >"$body_file"

# --- ship ---

if $dry_run; then
  step "Dry run — nothing was changed"
  log ""
  log "Branch that would be created: $branch"
  log "Title: $title"
  log ""
  log "--- file changes ---"
  git -C "$worktree" --no-pager diff --stat -- "charts/$chart" >&2 || true
  git -C "$worktree" status --porcelain -- "charts/$chart" >&2
  log ""
  log "--- PR body ---"
  cat "$body_file" >&2
  exit 0
fi

step "Committing"
git -C "$worktree" add -- "charts/$chart"
git -C "$worktree" commit --quiet -m "$title"
committed=true
log "  $branch"

if ! $open_pr; then
  step "Done (--no-pr): branch '$branch' created locally, not pushed"
  exit 0
fi

step "Pushing and opening the draft PR"
git -C "$worktree" push --quiet --set-upstream origin "$branch"
pr_url="$( cd "$worktree" && gh pr create \
  --base main --head "$branch" --draft \
  --title "$title" --body-file "$body_file" )"

step "Draft PR created"
log "  $pr_url"

# The URL is the script's only stdout output, so callers can capture it while
# progress logging stays on stderr.
printf '%s\n' "$pr_url"
