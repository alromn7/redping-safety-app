#!/usr/bin/env bash

set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
live_repo="$(cd "$script_dir/../.." && pwd)"
mirror_repo="/tmp/redping_14v-history-scrub.git"
remote_name="origin"

expected_remote_main="2fb4e6d807ff3ceaeae397dac8ee0bd4d4bd808f"
expected_remote_dev="de41ded25bea3e503caaba2b1f647e8654a6ca52"
expected_remote_release="c5ed8409b2b6ed86a7375822383f40c953625ef4"

release_ref="release/safety-fund-removal-prep-2026-02-16"
release_source_ref="refs/remotes/origin/release/safety-fund-removal-prep-2026-02-16"

if [[ ! -d "$mirror_repo" ]]; then
  echo "Sanitized mirror not found: $mirror_repo" >&2
  exit 1
fi

if [[ ! -d "$live_repo/.git" ]]; then
  echo "Live repo not found: $live_repo" >&2
  exit 1
fi

remote_url="$(git -C "$live_repo" remote get-url "$remote_name")"
if [[ -z "$remote_url" ]]; then
  echo "Could not resolve $remote_name URL from $live_repo" >&2
  exit 1
fi

check_remote_ref() {
  local ref_name="$1"
  local expected_sha="$2"
  local actual_sha

  actual_sha="$(git -C "$mirror_repo" ls-remote "$remote_url" "refs/heads/$ref_name" | awk '{print $1}')"
  if [[ -z "$actual_sha" ]]; then
    echo "Remote branch refs/heads/$ref_name not found on $remote_url" >&2
    exit 1
  fi

  if [[ "$actual_sha" != "$expected_sha" ]]; then
    echo "Remote branch refs/heads/$ref_name moved." >&2
    echo "Expected: $expected_sha" >&2
    echo "Actual:   $actual_sha" >&2
    echo "Refresh the runbook inputs before force-pushing." >&2
    exit 1
  fi
}

remote_ref_exists() {
  local ref_name="$1"
  git -C "$mirror_repo" ls-remote "$remote_url" "refs/heads/$ref_name" | grep -q .
}

check_remote_ref "main" "$expected_remote_main"
check_remote_ref "dev/sensor-monitoring" "$expected_remote_dev"

push_release_ref=false
if remote_ref_exists "$release_ref"; then
  check_remote_ref "$release_ref" "$expected_remote_release"
  push_release_ref=true
else
  echo "Remote branch refs/heads/$release_ref is absent on $remote_url; skipping it."
fi

echo "Remote refs on $remote_url match expected pre-rewrite SHAs."
echo "Force-pushing sanitized branch history..."

branch_push_args=(
  refs/heads/main:refs/heads/main
  refs/heads/dev/sensor-monitoring:refs/heads/dev/sensor-monitoring
)

if [[ "$push_release_ref" == true ]]; then
  branch_push_args+=("$release_source_ref:refs/heads/$release_ref")
fi

git -C "$mirror_repo" push "$remote_url" --force "${branch_push_args[@]}"

echo "Force-pushing sanitized tags..."
git -C "$mirror_repo" push "$remote_url" --force --tags

echo
echo "Sanitized history push complete."
echo "Next: follow docs/security/HISTORY_SCRUB_MIGRATION_RUNBOOK.md to re-home the live worktree safely."