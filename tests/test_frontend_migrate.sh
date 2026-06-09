#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/../.." && pwd)"
BIN="$PROJECT_DIR/frontend-migrate-agent/bin/frontend-migrate"
TMP_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/frontend-migrate-test.XXXXXX")"

cleanup() {
  rm -rf "$TMP_ROOT"
}
trap cleanup EXIT

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

assert_contains() {
  local haystack="$1"
  local needle="$2"
  if [[ "$haystack" != *"$needle"* ]]; then
    printf 'Output did not contain expected text:\n%s\n' "$needle" >&2
    printf 'Actual output:\n%s\n' "$haystack" >&2
    exit 1
  fi
}

init_repo() {
  local repo="$1"
  local branch="$2"
  mkdir -p "$repo"
  git -C "$repo" init -q
  git -C "$repo" config user.name "Test User"
  git -C "$repo" config user.email "test@example.com"
  printf '# test\n' > "$repo/README.md"
  git -C "$repo" add README.md
  git -C "$repo" commit -q -m "init"
  git -C "$repo" branch -M "$branch"
}

test_dry_run_defaults_to_frontend_contractweb_and_current_branch() {
  local backend="$TMP_ROOT/dry-run-backend"
  init_repo "$backend" "backend-feature"

  local output
  output="$(cd "$backend" && "$BIN" "https://example.com/frontend.git" "feature-ui" --dry-run 2>&1)"

  assert_contains "$output" "git remote add"
  assert_contains "$output" "https://example.com/frontend.git"
  assert_contains "$output" "git subtree add --prefix=frontend-contractweb"
  assert_contains "$output" "feature-ui"
  assert_contains "$output" "git push origin backend-feature"
}

test_dry_run_supports_prefix_and_squash() {
  local backend="$TMP_ROOT/prefix-backend"
  init_repo "$backend" "backend-main"

  local output
  output="$(cd "$backend" && "$BIN" "https://example.com/frontend.git" "main" --prefix frontend-operation --squash --dry-run 2>&1)"

  assert_contains "$output" "git subtree add --prefix=frontend-operation"
  assert_contains "$output" "--squash"
  assert_contains "$output" "git push origin backend-main"
}

test_fails_outside_git_repository() {
  local not_repo="$TMP_ROOT/not-repo"
  mkdir -p "$not_repo"

  local output
  if output="$(cd "$not_repo" && "$BIN" "https://example.com/frontend.git" "main" --dry-run 2>&1)"; then
    fail "expected command to fail outside a git repository"
  fi

  assert_contains "$output" "当前目录不是 git 仓库"
}

test_migrates_local_frontend_repo_and_pushes_current_backend_branch() {
  local frontend="$TMP_ROOT/frontend"
  local backend="$TMP_ROOT/backend"
  local origin="$TMP_ROOT/origin.git"

  init_repo "$frontend" "v1"
  mkdir -p "$frontend/src"
  printf 'console.log("frontend");\n' > "$frontend/src/main.js"
  git -C "$frontend" add src/main.js
  git -C "$frontend" commit -q -m "add frontend app"

  init_repo "$backend" "backend-feature"
  git init -q --bare "$origin"
  git -C "$backend" remote add origin "$origin"

  (cd "$backend" && "$BIN" "$frontend" "v1" --prefix frontend-console >/tmp/frontend-migrate-test-output.log 2>&1)

  [[ -f "$backend/frontend-console/src/main.js" ]] || fail "expected migrated frontend file"
  if git -C "$backend" remote | grep -q '^frontend-migrate-'; then
    fail "expected temporary frontend remote to be removed"
  fi
  git ls-remote --exit-code --heads "$origin" "backend-feature" >/dev/null || fail "expected current backend branch to be pushed"
}

test_dry_run_defaults_to_frontend_contractweb_and_current_branch
test_dry_run_supports_prefix_and_squash
test_fails_outside_git_repository
test_migrates_local_frontend_repo_and_pushes_current_backend_branch

printf 'PASS: frontend-migrate tests\n'
