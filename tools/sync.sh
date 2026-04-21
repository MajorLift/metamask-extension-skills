#!/usr/bin/env bash
# sync.sh — pull latest metamask-extension-skills and install into a target repo.
#
# Usage:
#   sync.sh --target <path>                        # install into consuming repo (tracks main)
#   sync.sh --target <path> --ref <tag|sha|branch> # pin to a specific ref (supply-chain safety)
#   sync.sh --target <path> --user                 # user-level install (no repo)
#   sync.sh --target <path> --tools-only           # shell tools only, skip skills/commands
#   sync.sh --target <path> --dry-run              # preview
#
# Invoked by `yarn skills:sync` from a consuming repo, or via curl|bash one-liner.

set -euo pipefail

TARGET=""
REF="main"
USER_MODE=false
TOOLS_ONLY=false
DRY_RUN=false
NO_SYMLINKS=false

usage() {
  echo "Usage: $0 --target <path> [--ref <tag|sha|branch>] [--user] [--tools-only] [--dry-run] [--no-symlinks]"
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --target)       TARGET="$2"; shift 2 ;;
    --ref)          REF="$2"; shift 2 ;;
    --user)         USER_MODE=true; shift ;;
    --tools-only)   TOOLS_ONLY=true; shift ;;
    --dry-run)      DRY_RUN=true; shift ;;
    --no-symlinks)  NO_SYMLINKS=true; shift ;;
    *) usage ;;
  esac
done

[[ -z "$TARGET" ]] && usage
[[ ! -d "$TARGET" ]] && { echo "Error: target directory does not exist: $TARGET" >&2; exit 1; }

SRC_REPO="https://github.com/MajorLift/metamask-extension-skills.git"
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

echo "Cloning ${SRC_REPO} (ref=${REF}) ..."
# Try shallow clone at ref first. Fall back to full clone + checkout for arbitrary SHAs.
if ! git clone --depth 1 --branch "$REF" --quiet "$SRC_REPO" "$TMPDIR" 2>/dev/null; then
  echo "Shallow clone failed for ref '${REF}' — falling back to full clone + checkout."
  rm -rf "$TMPDIR" && TMPDIR=$(mktemp -d)
  git clone --quiet "$SRC_REPO" "$TMPDIR"
  (cd "$TMPDIR" && git checkout --quiet "$REF")
fi
SHA=$(cd "$TMPDIR" && git rev-parse HEAD)
SHORT_SHA=$(cd "$TMPDIR" && git rev-parse --short HEAD)

INSTALL_ARGS=("--target" "$TARGET")
$DRY_RUN      && INSTALL_ARGS+=("--dry-run")
$USER_MODE    && INSTALL_ARGS+=("--user")
$TOOLS_ONLY   && INSTALL_ARGS+=("--tools-only")
$NO_SYMLINKS  && INSTALL_ARGS+=("--no-symlinks")

# Repo name inferred from target dir basename for consuming-repo mode.
if ! $USER_MODE; then
  REPO_NAME=$(basename "$(cd "$TARGET" && pwd)")
  INSTALL_ARGS+=("--repo" "$REPO_NAME")
fi

bash "$TMPDIR/tools/install.sh" "${INSTALL_ARGS[@]}"

if ! $DRY_RUN; then
  mkdir -p "$TARGET/.skills"
  cat > "$TARGET/.skills/VERSION" <<EOF
synced_ref=${REF}
synced_sha=${SHA}
synced_at=$(date -u +%Y-%m-%dT%H:%M:%SZ)
source=${SRC_REPO}
EOF
fi

echo
echo "✓ skills synced: ${REF}@${SHORT_SHA} → ${TARGET}"
$USER_MODE || echo "  Alias suggestion: alias remember='./.skills/remember.sh' && alias patch-skill='./.skills/patch.sh'"
