#!/usr/bin/env bash
# install.sh — install skills into a consuming repo using the Agent Skills standard.
#
# Single source of truth: domains/<domain>/skills/<slug>/skill.md
# Platform adapters (.claude/, .cursor/, .agents/) are generated locally at
# sync time — no duplicate files live upstream.
#
#   * Skills       → canonical at .agents/skills/shared/<slug>/SKILL.md; shimmed
#                    into .claude/skills/<slug>/SKILL.md and
#                    .cursor/skills/<slug>/SKILL.md (symlinks by default, or
#                    copies with --no-symlinks). The `shared/` subdir isolates
#                    synced content from consumer-authored skills at
#                    .agents/skills/<slug>/.
#                    .cursor/skills/ is Cursor's slash-command surface — a skill
#                    slug that matches its `command:` frontmatter surfaces as `/name`.
#   * Slash cmds   → a skill opts in by setting `command: <name>` in frontmatter.
#                    Sync generates .claude/commands/<name>.md from the skill body
#                    with Claude-Code-specific frontmatter. No separate Cursor
#                    command file — the skill shim is Cursor's slash surface.
#
# All generated directories should be gitignored in the consuming repo:
#     /.agents/skills/shared/
#     /.claude/skills/
#     /.claude/commands/
#     /.cursor/skills/
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
#   <target>/.agents/skills/shared/<slug>/SKILL.md    ← canonical (Agent Skills standard, synced)
#   <target>/.claude/skills/<slug>/SKILL.md           ← shim → ../../../.agents/skills/shared/<slug>/SKILL.md
#   <target>/.cursor/skills/<slug>/SKILL.md           ← shim → ../../../.agents/skills/shared/<slug>/SKILL.md
#   <target>/.claude/commands/<cmd>.md                ← generated from skill (frontmatter: command)
#   <target>/.skills/{remember.sh,patch.sh,sync.sh}   ← shell fallback (copied)

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

CLAUDE_SKILLS_DIR="$CLAUDE_DIR/skills"
CURSOR_SKILLS_DIR="$CURSOR_DIR/skills"

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

# read_frontmatter <file> <key> — prints the value of a top-level frontmatter key.
# Only reads the first YAML block (between the first two '---' lines).
read_frontmatter() {
  awk -v key="$2" '
    /^---$/ { c++; if (c == 2) exit; next }
    c == 1 {
      if (match($0, "^" key ":[[:space:]]*")) {
        v = substr($0, RLENGTH + 1)
        sub(/[[:space:]]+$/, "", v)
        print v; exit
      }
    }
  ' "$1"
}

# body_after_frontmatter <file> — prints body lines below the frontmatter block.
body_after_frontmatter() {
  awk '
    !started && /^---$/ { c++; if (c == 2) { started=1; next } next }
    started { print }
  ' "$1"
}

# generate_claude_command <skill_file> <cmd_name>
generate_claude_command() {
  local file="$1" cmd="$2" out="$CLAUDE_DIR/commands/$2.md"
  local desc; desc=$(read_frontmatter "$file" description)
  local hint; hint=$(read_frontmatter "$file" argument-hint)
  run "mkdir -p '$CLAUDE_DIR/commands'"
  if $DRY_RUN; then
    echo "DRY: generate Claude command → $out"
    return
  fi
  {
    echo "---"
    [[ -n "$desc" ]] && echo "description: $desc"
    [[ -n "$hint" ]] && echo "argument-hint: $hint"
    echo "---"
    echo
    body_after_frontmatter "$file"
  } > "$out"
}

FILTER=$(echo "$INCLUDE_MATURITY" | tr ',' '|')

# ---------- slash commands (both repo and user modes — --user installs commands at ~/.claude/commands/) ----------
if [[ -d "$SRC_ROOT/domains" ]]; then
  find "$SRC_ROOT/domains" -name 'skill.md' | while read -r file; do
    mat=$(read_frontmatter "$file" maturity)
    [[ -z "$mat" ]] && mat="experimental"
    echo "$mat" | grep -qE "^($FILTER)$" || continue
    cmd=$(read_frontmatter "$file" command)
    if [[ -n "$cmd" ]]; then
      generate_claude_command "$file" "$cmd"
    fi
  done
fi

# ---------- skills (repo mode only — canonical + shims) ----------
if ! $USER_MODE && [[ -d "$SRC_ROOT/domains" ]]; then
  run "mkdir -p '$AGENTS_DIR/skills/shared' '$CLAUDE_SKILLS_DIR' '$CURSOR_SKILLS_DIR'"

  find "$SRC_ROOT/domains" -name 'skill.md' | while read -r file; do
    mat=$(read_frontmatter "$file" maturity)
    [[ -z "$mat" ]] && mat="experimental"
    echo "$mat" | grep -qE "^($FILTER)$" || continue
    slug=$(basename "$(dirname "$file")")

    # Canonical: .agents/skills/shared/<slug>/SKILL.md
    # The shared/ subdir isolates synced content from consumer-authored skills
    # that may live alongside at .agents/skills/<slug>/.
    canonical="$AGENTS_DIR/skills/shared/$slug/SKILL.md"
    run "mkdir -p '$AGENTS_DIR/skills/shared/$slug'"
    run "cp '$file' '$canonical'"

    # Shim: .claude/skills/<slug>/SKILL.md → ../../../.agents/skills/shared/<slug>/SKILL.md
    shim "$canonical" \
         "$CLAUDE_SKILLS_DIR/$slug/SKILL.md" \
         "../../../.agents/skills/shared/$slug/SKILL.md"

    # Shim: .cursor/skills/<slug>/SKILL.md → ../../../.agents/skills/shared/<slug>/SKILL.md
    shim "$canonical" \
         "$CURSOR_SKILLS_DIR/$slug/SKILL.md" \
         "../../../.agents/skills/shared/$slug/SKILL.md"
  done
fi

echo "✓ install complete (target=$TARGET user=$USER_MODE tools_only=$TOOLS_ONLY symlinks=$([[ $NO_SYMLINKS == true ]] && echo off || echo on) maturity=$INCLUDE_MATURITY)"

# ---------- reminder ----------
if ! $USER_MODE && ! $DRY_RUN; then
  cat <<EOF

  Add to ${REPO_NAME}/.gitignore if not already present:
    /.agents/skills/shared/
    /.claude/skills/
    /.claude/commands/
    /.cursor/skills/
    /.skills/
  (Generated on every sync. Never hand-edit — edit source in metamask-extension-skills.)
EOF
fi
