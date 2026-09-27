#!/usr/bin/env python3
"""Check a repo's agent setup against the Agent Skills spec and this setup's rules.

Usage:
  check-repo.py [REPO_DIR] [--no-global]

  REPO_DIR     repo root, default: current directory
  --no-global  skip checks against the user's global skills (for CI, or a
               machine without them)

FAIL (exit 1):
  - AGENTS.md missing at the root, or over 32 KiB (Codex stops reading there)
  - a root CLAUDE.md that does not import @AGENTS.md (Claude then ignores AGENTS.md)
  - skills kept in an agent-specific place: .claude/commands, .claude/agents,
    .cursor/skills, .codex/skills, or .claude/skills as a real dir
  - .agents/skills present but .claude/skills not a symlink to it
  - a skill breaking the spec: name must be lowercase-hyphenated, <= 64 chars
    and match its folder; description 1-1024 chars
  - invocation mismatch: Claude's disable-model-invocation vs Codex's
    agents/openai.yaml allow_implicit_invocation
  - an operative dependency ("Call the Skill tool with ...") on a skill that
    is missing or manual
  - a repo skill named like a global skill (Claude runs the global one)
  - a skills-lock.json entry with no folder

WARN (exit 0):
  - AGENTS.md over 200 lines, SKILL.md over 500 lines
  - scripts inside vendored (lock-listed) skills: review before trusting
"""
import json
import os
import re
import sys
from pathlib import Path

NAME_RE = re.compile(r"^[a-z0-9]+(-[a-z0-9]+)*$")
DEP_RE = re.compile(r'Call the Skill tool (?:with|twice, for|for) ((?:"[a-z0-9-]+"(?:,? (?:and )?)?)+)')
GLOBAL_DIRS = [Path.home() / ".claude/skills", Path.home() / ".agents/skills"]
LEGACY = [".claude/commands", ".claude/agents", ".cursor/skills", ".codex/skills"]

fails: list[str] = []
warns: list[str] = []


def frontmatter(md: Path) -> dict[str, str]:
    m = re.match(r"^---\n(.*?)\n---\n", md.read_text(), re.S)
    fields: dict[str, str] = {}
    key = None
    for line in (m.group(1).splitlines() if m else []):
        km = re.match(r"^([A-Za-z_-]+):\s*(.*)$", line)
        if km:
            key = km.group(1)
            fields[key] = km.group(2).strip().strip('"')
        elif key and line.startswith(" "):
            fields[key] = (fields[key] + " " + line.strip()).strip()
    return fields


def manual(skill: Path) -> bool:
    return frontmatter(skill / "SKILL.md").get("disable-model-invocation") == "true"


def codex_manual(skill: Path) -> bool:
    y = skill / "agents/openai.yaml"
    return y.is_file() and re.search(
        r"^\s*allow_implicit_invocation:\s*false\s*$", y.read_text(), re.M) is not None


def skill_dirs(root: Path) -> list[Path]:
    if not root.is_dir():
        return []
    return sorted(p for p in root.iterdir() if (p / "SKILL.md").is_file())


def check_instructions(repo: Path) -> None:
    agents = repo / "AGENTS.md"
    if not agents.is_file():
        fails.append("AGENTS.md missing at the repo root")
    else:
        size, lines = agents.stat().st_size, len(agents.read_text().splitlines())
        if size > 32 * 1024:
            fails.append(f"AGENTS.md is {size} bytes; Codex stops reading at 32 KiB")
        if lines > 200:
            warns.append(f"AGENTS.md is {lines} lines; Claude's docs advise under 200")
    for claude in (repo / "CLAUDE.md", repo / ".claude/CLAUDE.md"):
        if claude.is_file() and not re.search(r"^@(\./)?(\.\./)?AGENTS\.md\s*$", claude.read_text(), re.M):
            fails.append(f"{claude.relative_to(repo)} exists without an @AGENTS.md import, so Claude ignores AGENTS.md")


def check_layout(repo: Path) -> None:
    for rel in LEGACY:
        d = repo / rel
        if d.is_dir() and any(d.iterdir()):
            fails.append(f"{rel}/ holds agent-specific skills; move them to .agents/skills/")
    shared, claude = repo / ".agents/skills", repo / ".claude/skills"
    if claude.exists() and not claude.is_symlink():
        fails.append(".claude/skills is a real dir; make it a symlink to ../.agents/skills")
    elif shared.is_dir() and (not claude.is_symlink() or claude.resolve() != shared.resolve()):
        fails.append(".claude/skills must be a symlink to ../.agents/skills (Claude reads only .claude/skills)")


def global_skills() -> dict[str, bool]:
    """Global skill name -> is manual. Empty when none are installed."""
    out: dict[str, bool] = {}
    for d in GLOBAL_DIRS:
        for s in skill_dirs(d):
            out.setdefault(s.name, manual(s))
    return out


def check_skills(repo: Path, globals_: dict[str, bool]) -> None:
    skills = skill_dirs(repo / ".agents/skills")
    local = {s.name: manual(s) for s in skills}
    locked: set[str] = set()
    lock = repo / "skills-lock.json"
    if lock.is_file():
        locked = set(json.loads(lock.read_text()).get("skills", {}))
        for n in sorted(locked - set(local)):
            fails.append(f"skills-lock.json lists {n!r} but .agents/skills/{n} is missing")

    for s in skills:
        fm, md = frontmatter(s / "SKILL.md"), s / "SKILL.md"
        name, desc = fm.get("name", ""), fm.get("description", "")
        if name != s.name:
            fails.append(f"{s.name}: frontmatter name {name!r} must match the folder")
        if not NAME_RE.match(s.name) or len(s.name) > 64:
            fails.append(f"{s.name}: name must be lowercase letters, digits and single hyphens, <= 64 chars")
        if not 1 <= len(desc) <= 1024:
            fails.append(f"{s.name}: description must be 1-1024 chars (is {len(desc)})")
        if manual(s) != codex_manual(s):
            fails.append(f"{s.name}: Claude manual={manual(s)} but Codex manual={codex_manual(s)}; "
                         "set both disable-model-invocation and agents/openai.yaml policy")
        if len(md.read_text().splitlines()) > 500:
            warns.append(f"{s.name}: SKILL.md over 500 lines; move detail into references/")
        if s.name in globals_:
            fails.append(f"{s.name}: same name as a global skill; Claude runs the global one. Rename it")
        for m in DEP_RE.finditer(md.read_text()):
            for dep in re.findall(r'"([a-z0-9-]+)"', m.group(1)):
                is_manual = local.get(dep, globals_.get(dep))
                if is_manual is None:
                    if globals_ or dep in local:
                        fails.append(f"{s.name}: depends on missing skill {dep!r}")
                elif is_manual:
                    fails.append(f"{s.name}: depends on manual skill {dep!r}, which no skill can call")
        if s.name in locked:
            scripts = [p for p in s.rglob("*") if p.is_file() and p.parent.name == "scripts"]
            if scripts:
                warns.append(f"{s.name}: vendored scripts to review before trusting: "
                             + ", ".join(str(p.relative_to(s)) for p in scripts))


def main() -> int:
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    repo = Path(args[0] if args else os.getcwd()).resolve()
    globals_ = {} if "--no-global" in sys.argv else global_skills()
    check_instructions(repo)
    check_layout(repo)
    check_skills(repo, globals_)
    for w in warns:
        print(f"WARN  {w}")
    for f in fails:
        print(f"FAIL  {f}")
    n = len(skill_dirs(repo / ".agents/skills"))
    scope = "no global skills checked" if not globals_ else f"{len(globals_)} global skills checked for clashes"
    print(("ok" if not fails else f"{len(fails)} failure(s)") + f": {repo.name}, {n} repo skills, {scope}")
    return 1 if fails else 0


if __name__ == "__main__":
    sys.exit(main())
