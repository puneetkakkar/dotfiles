#!/usr/bin/env bash
# Link the agent-neutral setup in agents/ into every coding agent's user dirs.
#
# Used by bootstrap.sh and scripts/link-agents. Sourced, not executed.
# Requires lib/symlink.sh (link_file) and DOTFILES_REPO.
#
# Skills: each agents/skills/<name> is linked into every agent's user skills
# dir. Linking per skill, not the whole dir, leaves anything else in there
# alone (e.g. ~/.claude/skills/synced from the claude.ai account).
# Instructions: agents/AGENTS.md is linked at each agent's global path.
#
# Claude Code and Codex are always linked. Other agents only when their config
# dir exists, so a machine without them gets no stray dirs.
# Keep these lists in sync with SKILL_TARGETS / INSTRUCTION_TARGETS in
# scripts/check-agents.

agent_skill_dirs() {
  printf '%s\n' "$HOME/.claude/skills" "$HOME/.agents/skills"
  [ -d "$HOME/.cursor" ] && printf '%s\n' "$HOME/.cursor/skills"
  [ -d "$HOME/.gemini" ] && printf '%s\n' "$HOME/.gemini/skills"
  [ -d "$HOME/.config/opencode" ] && printf '%s\n' "$HOME/.config/opencode/skills"
  return 0
}

agent_instruction_files() {
  printf '%s\n' "$HOME/.claude/CLAUDE.md" "$HOME/.codex/AGENTS.md"
  [ -d "$HOME/.gemini" ] && printf '%s\n' "$HOME/.gemini/GEMINI.md"
  [ -d "$HOME/.config/opencode" ] && printf '%s\n' "$HOME/.config/opencode/AGENTS.md"
  return 0
}

link_agents() {
  local src="$DOTFILES_REPO/agents" dir skill entry

  while IFS= read -r dir; do
    mkdir -p "$dir"
    # Drop links into this repo whose skill was removed or renamed.
    for entry in "$dir"/*; do
      if [ -L "$entry" ] && [ ! -e "$entry" ]; then
        case "$(readlink "$entry")" in
          "$DOTFILES_REPO"/*) rm "$entry"; printf '  [prune] %s\n' "$entry" ;;
        esac
      fi
    done
    for skill in "$src"/skills/*/; do
      skill="${skill%/}"
      link_file "$skill" "$dir/$(basename "$skill")"
    done
  done < <(agent_skill_dirs)

  while IFS= read -r entry; do
    link_file "$src/AGENTS.md" "$entry"
  done < <(agent_instruction_files)
}
