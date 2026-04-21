#!/usr/bin/env bash
# install.sh — install skills into a consuming repo using the Agent Skills standard.
#
# Canonical location: .agents/skills/<slug>/SKILL.md
# Adapter paths (.claude/skills/<slug>/SKILL.md, .cursor/rules/<slug>.mdc) are
# generated as symlink shims pointing to the canonical file — no content
# duplication. On filesystems without symlink support, pass --no-symlinks to
# fall back to file copies.
#
# All generated directories should be gitignored in the consuming repo:
#     /.agents/skills/
#     /.claude/skills/
#     /.cursor/rules/
#     /.skills/
#
# Modes:
#   --target <path>                install into consuming repo (default)
#   --target <path> --user         user-level install (~/.claude, ~/.cursor); no repo writes
#   --target <path> --tools-only   install shell tools only (skip skills, commands)
#   --target <path> --dry-run      print what would happen, write nothing
#   --target <path> --no-symlinks  copy files instead of symlinking shims
#
# Layout (repo mode):
#   <target>/.agents/skills/<slug>/SKILL.md    ← canonical (Agent Skills standard)
#   <target>/.claude/skills/<slug>/SKILL.md    ← shim → ../../../.agents/skills/<slug>/SKILL.md
#   <target>/.cursor/rules/<slug>.mdc          ← shim → ../../.agents/skills/<slug>/SKILL.md
#   <target>/.claude/commands/<name>.md        ← /remember, /patch, /backfill (copied)
#   <target>/.cursor/rules/<name>.mdc          ← Cursor fallbacks (copied)
#   <target>/.skills/{remember.sh,patch.sh,sync.sh}  ← shell fallback (copied)
#
# User mode (--user) writes only the command specs + shell tools into
# ~/.claude, ~/.cursor, ~/.skills. Skills are repo-scoped only.

set -euo pipefail

SRC_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TARGET=""
USER_MODE=false
TOOLS_ONLY=false
DRY_RUN=false
NO_SYMLINKS=false
REPO_NAME=""
INCLUDE_MATURITY="stable,experimental,draft"  # override with --include-maturity

usage() {
  cat <<EOF
Usage: $0 --target <path> [options]

Options:
  --user                  user-level install (~/.claude, ~/.cursor, ~/.skills)
  --tools-only            shell tools only, skip skills + commands
  --dry-run               preview actions, write nothing
  --no-symlinks           copy shims instead of symlinking (Windows / no-symlink FS)
  --repo <name>           repo name (inferred from target basename)
  --include-maturity <l>  comma list of maturity tiers to include
                          (default: stable,experimental,draft — narrow to
                          'stable' once the catalog has promoted skills)
EOF
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --target)            TARGET="$2"; shift 2 ;;
    --user)              USER_MODE=true; shift ;;
    --tools-only)        TOOLS_ONLY=true; shift ;;
    --dry-run)           DRY_RUN=true; shift ;;
    --no-symlinks)       NO_SYMLINKS=true; shift ;;
    --repo)              REPO_NAME="$2"; shift 2 ;;
    --include-maturity)  INCLUDE_MATURITY="$2"; shift 2 ;;
    -h|--help)           usage ;;
    *) echo "Unknown arg: $1" >&2; usage ;;
  esac
done

[[ -z "$TARGET" ]] && usage
[[ ! -d "$TARGET" ]] && { echo "Error: target not a directory: $TARGET" >&2; exit 1; }

if $USER_MODE; then
  CLAUDE_DIR="$HOME/.claude"
  CURSOR_DIR="$HOME/.cursor"
  SKILLS_TOOLS_DIR="$HOME/.skills"
else
  AGENTS_DIR="$TARGET/.agents"
  CLAUDE_DIR="$TARGET/.claude"
  CURSOR_DIR="$TARGET/.cursor"
  SKILLS_TOOLS_DIR="$TARGET/.skills"
  [[ -z "$REPO_NAME" ]] && REPO_NAME=$(basename "$(cd "$TARGET" && pwd)")
fi

run() {
  if $DRY_RUN; then
    echo "DRY: $*"
  else
    eval "$@"
  fi
}

# shim <canonical> <shim_path> <relative_from_shim>
# If symlinks disabled, copies the canonical file to shim_path. Otherwise
# creates a relative symlink — portable and survives repo moves.
shim() {
  local canonical="$1"
  local shim_path="$2"
  local rel="$3"
  run "mkdir -p '$(dirname "$shim_path")'"
  run "rm -f '$shim_path'"
  if $NO_SYMLINKS; then
    run "cp '$canonical' '$shim_path'"
  else
    run "ln -s '$rel' '$shim_path'"
  fi
}

# ---------- shell tools (always installed) ----------
if [[ -d "$SRC_ROOT/tools" ]]; then
  run "mkdir -p '$SKILLS_TOOLS_DIR'"
  for t in remember.sh patch.sh sync.sh; do
    if [[ -f "$SRC_ROOT/tools/$t" ]]; then
      run "cp '$SRC_ROOT/tools/$t' '$SKILLS_TOOLS_DIR/$t'"
      run "chmod +x '$SKILLS_TOOLS_DIR/$t'"
    fi
  done
fi

$TOOLS_ONLY && { echo "✓ tools-only install complete"; exit 0; }

# ---------- command specs (copied — per-tool, no canonical) ----------
if [[ -d "$SRC_ROOT/commands" ]]; then
  run "mkdir -p '$CLAUDE_DIR/commands' '$CURSOR_DIR/rules'"
  for cmd in remember patch backfill; do
    [[ -f "$SRC_ROOT/commands/$cmd.md"         ]] && run "cp '$SRC_ROOT/commands/$cmd.md'         '$CLAUDE_DIR/commands/$cmd.md'"
    [[ -f "$SRC_ROOT/commands/$cmd.cursor.mdc" ]] && run "cp '$SRC_ROOT/commands/$cmd.cursor.mdc' '$CURSOR_DIR/rules/$cmd.mdc'"
  done
fi

# ---------- skills (repo mode only — canonical + shims) ----------
if ! $USER_MODE && [[ -d "$SRC_ROOT/domains" ]]; then
  run "mkdir -p '$AGENTS_DIR/skills' '$CLAUDE_DIR/skills' '$CURSOR_DIR/rules'"

  FILTER=$(echo "$INCLUDE_MATURITY" | tr ',' '|')

  find "$SRC_ROOT/domains" -name 'skill.md' | while read -r file; do
    mat=$(awk '/^maturity: */{print $2; exit}' "$file" 2>/dev/null || echo "")
    [[ -z "$mat" ]] && mat="experimental"
    if ! echo "$mat" | grep -qE "^($FILTER)$"; then
      continue
    fi
    slug=$(basename "$(dirname "$file")")

    # Canonical: .agents/skills/<slug>/SKILL.md (Agent Skills standard naming)
    canonical="$AGENTS_DIR/skills/$slug/SKILL.md"
    run "mkdir -p '$AGENTS_DIR/skills/$slug'"
    run "cp '$file' '$canonical'"

    # Shim: .claude/skills/<slug>/SKILL.md → ../../../.agents/skills/<slug>/SKILL.md
    shim "$canonical" \
         "$CLAUDE_DIR/skills/$slug/SKILL.md" \
         "../../../.agents/skills/$slug/SKILL.md"

    # Shim: .cursor/rules/<slug>.mdc → ../../.agents/skills/<slug>/SKILL.md
    shim "$canonical" \
         "$CURSOR_DIR/rules/$slug.mdc" \
         "../../.agents/skills/$slug/SKILL.md"
  done
fi

echo "✓ install complete (target=$TARGET user=$USER_MODE tools_only=$TOOLS_ONLY symlinks=$([[ $NO_SYMLINKS == true ]] && echo off || echo on) maturity=$INCLUDE_MATURITY)"

# ---------- reminder ----------
if ! $USER_MODE && ! $DRY_RUN; then
  cat <<EOF

  Add to ${REPO_NAME}/.gitignore if not already present:
    /.agents/skills/
    /.claude/skills/
    /.cursor/rules/
    /.skills/
  (Generated on every sync. Never hand-edit — edit source in metamask-extension-skills.)
EOF
fi
