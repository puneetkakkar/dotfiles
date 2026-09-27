#!/usr/bin/env python3
"""Check the installed Codex CLI sees agents/ the way the repo intends.

Needs `codex` on PATH but no login and no model calls: it asks the local
app-server which skills it loaded (`skills/list`) and renders the
model-visible prompt (`codex debug prompt-input`). Run after
scripts/link-agents:

  tests/test-codex.py

Checks:
  1. every repo skill is loaded, user scope, enabled, from this repo, and
     Codex reports no skill load errors
  2. Codex parsed each agents/openai.yaml (its display_name comes back)
  3. the model's skill list is exactly the model-invoked set: manual skills
     (allow_implicit_invocation: false) stay out of the prompt
  4. agents/AGENTS.md is in the prompt as global instructions
"""
import json
import re
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

REPO = Path(__file__).resolve().parent.parent
SKILLS = REPO / "agents/skills"
passed = failed = 0


def ok(msg: str) -> None:
    global passed
    passed += 1
    print(f"  ok    {msg}")


def bad(msg: str, detail: str = "") -> None:
    global failed
    failed += 1
    print(f"  FAIL  {msg}" + (f"\n        {detail}" if detail else ""))


def repo_skills() -> dict[str, dict]:
    out = {}
    for d in sorted(p for p in SKILLS.iterdir() if p.is_dir()):
        fm = (d / "SKILL.md").read_text()
        yaml = d / "agents/openai.yaml"
        ytext = yaml.read_text() if yaml.exists() else ""
        dn = re.search(r'display_name:\s*"([^"]*)"', ytext)
        out[d.name] = {
            "manual": re.search(r"^disable-model-invocation:\s*true\s*$", fm, re.M) is not None,
            "display_name": dn.group(1) if dn else None,
        }
    return out


def skills_list(cwd: str) -> dict:
    """JSON-RPC over stdio: initialize, then skills/list; return the response."""
    msgs = [
        {"jsonrpc": "2.0", "id": 0, "method": "initialize",
         "params": {"clientInfo": {"name": "dotfiles-test", "version": "0.1"}}},
        {"jsonrpc": "2.0", "method": "initialized"},
        {"jsonrpc": "2.0", "id": 1, "method": "skills/list",
         "params": {"cwds": [cwd], "forceReload": True}},
    ]
    p = subprocess.Popen(["codex", "app-server"], cwd=cwd, stdin=subprocess.PIPE,
                         stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, text=True)
    assert p.stdin and p.stdout
    for m in msgs:
        p.stdin.write(json.dumps(m) + "\n")
    p.stdin.flush()
    try:
        for line in p.stdout:
            try:
                d = json.loads(line)
            except ValueError:
                continue
            if d.get("id") == 1:
                return d
    finally:
        p.kill()
    return {}


def prompt_text(cwd: str) -> str:
    out = subprocess.run(["codex", "debug", "prompt-input", "hello"], cwd=cwd,
                         capture_output=True, text=True, check=True).stdout
    items = json.loads(out)
    return "\n".join(c.get("text", "") for it in items
                     for c in (it.get("content") or []) if isinstance(c, dict))


def main() -> int:
    if not shutil.which("codex"):
        print("codex not installed; skipping (brew install --cask codex)")
        return 0
    want = repo_skills()
    model_invoked = {n for n, s in want.items() if not s["manual"]}
    manual = set(want) - model_invoked

    with tempfile.TemporaryDirectory() as w:
        subprocess.run(["git", "init", "-q", w], check=True)

        print("1. every skill loaded from this repo")
        resp = skills_list(w)
        if "result" not in resp:
            bad("skills/list failed", str(resp.get("error", "no response")))
            loaded = {}
        else:
            entry = resp["result"]["data"][0]
            if entry["errors"]:
                bad("Codex reported skill load errors", json.dumps(entry["errors"]))
            else:
                ok("no skill load errors")
            loaded = {s["name"]: s for s in entry["skills"]}
        for name in want:
            s = loaded.get(name)
            if not s:
                bad(f"not loaded: {name}")
            elif s.get("scope") != "user" or not s.get("enabled"):
                bad(f"{name}: scope={s.get('scope')} enabled={s.get('enabled')}")
            elif not Path(s["path"]).resolve().is_relative_to(SKILLS):
                bad(f"{name}: loaded from {s['path']}, not this repo")
        if all(n in loaded for n in want):
            ok(f"all {len(want)} skills loaded, user scope, enabled, from agents/skills")

        print("2. agents/openai.yaml parsed")
        mismatched = 0
        for name, s in want.items():
            got = ((loaded.get(name) or {}).get("interface") or {}).get("displayName")
            if s["display_name"] and got != s["display_name"]:
                mismatched += 1
                bad(f"{name}: displayName {got!r}, expected {s['display_name']!r}")
        if not mismatched:
            ok("every display_name came back from Codex")

        print("3. model sees exactly the model-invoked set")
        text = prompt_text(w)
        root = re.search(r"`(r\d+)` = `([^`]*/\.agents/skills)`", text)
        if not root:
            bad("~/.agents/skills root not in the prompt")
            visible = set()
        else:
            visible = set(re.findall(
                rf"^- ([a-z0-9-]+): .*\(file: {root.group(1)}/[^)]*SKILL\.md\)$", text, re.M))
        missing, leaked = model_invoked - visible, manual & visible
        extra = visible - set(want)
        if missing:
            bad("model-invoked skills missing from the prompt", " ".join(sorted(missing)))
        if leaked:
            bad("manual skills visible to the model", " ".join(sorted(leaked)))
        if extra:
            bad("unexpected skills from ~/.agents/skills", " ".join(sorted(extra)))
        if not (missing or leaked or extra):
            ok(f"{len(visible)} model-invoked visible, {len(manual)} manual hidden")

        print("4. AGENTS.md loaded as global instructions")
        first = (REPO / "agents/AGENTS.md").read_text().splitlines()[0]
        ok(f"found {first!r}") if first in text else bad("AGENTS.md not in the prompt", first)

    print(f"\n{passed} passed, {failed} failed")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
