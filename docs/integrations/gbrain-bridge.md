# gbrain Bridge

Claude Mind can delegate brain operations to [`garrytan/gbrain`](https://github.com/garrytan/gbrain) when it's installed. The two are complementary: Claude Mind provides the persona/loop/taste; gbrain provides the production-grade brain.

## Enabling the bridge

In your repo's `settings.json` (or via `/sc-init` if gbrain was detected):

```json
{
  "claude-mind": {
    "gbrain_bridge_enabled": true
  }
}
```

The bridge requires:
- `gbrain` MCP server registered with Claude Code
- Claude Mind v0.1+

## What changes when the bridge is on

| Without bridge | With bridge |
|---|---|
| `/recall` — greps `./brain/` | `/recall` — calls `gbrain.search` (hybrid vector + keyword) |
| `brain-first` — five-step grep protocol | `brain-first` — gbrain hybrid search + the same five-step protocol as fallback |
| `Stop` hook — appends to `./brain/_journal.md` | `Stop` hook — also calls `gbrain.sync` after appending |
| `/remember` — writes markdown to `./brain/` | `/remember` — writes markdown + calls `gbrain.sync` |

The markdown brain pages remain the source of truth. gbrain reads them.

## When NOT to enable the bridge

- You're working on a one-off project where the brain doesn't matter long-term
- You don't have the time to set up gbrain (~30 minutes per the gbrain README)
- You're cost-sensitive about gbrain's recurring jobs

## Known limitations

- The bridge is one-way: Claude Mind → gbrain. We don't ingest gbrain's voice/email/calendar streams.
- `/sc-init` does not install gbrain; you have to do that separately.
- Tested against gbrain commits up through 2026-04-15. Newer gbrain may require bridge updates.
