---
name: uv-python
description: uv-first Python workflow — uv run, uv add, uv sync; no pip install by default
when-to-use: When working in any Python project (pyproject.toml or *.py present)
---

# uv-python

## The defaults

| Need | Use | Don't use |
|---|---|---|
| Run a script | `uv run script.py` | `python script.py` |
| Add a dependency | `uv add <pkg>` | `pip install <pkg>` |
| Add a dev dep | `uv add --dev <pkg>` | `pip install <pkg>` |
| Sync env to lockfile | `uv sync` | `pip install -r requirements.txt` |
| Run tests | `uv run pytest` | `pytest` |
| New project | `uv init` | `mkdir && touch setup.py` |

## Why uv

- ~10–100× faster than pip
- Replaces pip + virtualenv + pip-tools + pyenv with one tool
- Lockfile (`uv.lock`) is reproducible across machines
- Same project shape as pyproject.toml (PEP 621); no lock-in

## Install (once per machine)

```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
```

## Bootstrap on a fresh machine

```bash
cd <repo>
uv sync          # installs from uv.lock
uv run pytest    # everything goes through uv run
```

## When uv isn't installed

If `uv` isn't on PATH:
1. Detect: `command -v uv >/dev/null || ...`
2. Offer to install via the curl one-liner
3. If user declines, fall back to `pip` with a one-line note

Never silently use pip when uv would work.

## Standalone scripts (PEP 723)

For one-off scripts with deps, use uv's inline metadata:

```python
# /// script
# requires-python = ">=3.12"
# dependencies = ["httpx"]
# ///

import httpx
print(httpx.get("https://example.com").status_code)
```

Run with `uv run script.py` — no virtualenv setup required.

## Anti-patterns

- `pip install` in a uv project → corrupts the lockfile; use `uv add`
- `python` directly when `uv run python` would use the right env
- Hand-editing `pyproject.toml` deps when `uv add` would update both deps and lock
