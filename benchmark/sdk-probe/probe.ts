/**
 * SDK probe: does @anthropic-ai/claude-agent-sdk fire Claude Code hooks
 * (UserPromptSubmit, Stop, PreToolUse) when invoked from a Node.js script?
 *
 * The claude-mind plugin is installed at user scope and writes to ./brain/_signals.md
 * (UserPromptSubmit hook) and ./brain/_journal.md (Stop hook). If those files have
 * non-zero size after this probe runs, the hooks fired.
 *
 * Critical SDK detail (from sdk.d.ts on Options.settingSources):
 *   "When omitted or empty, no filesystem settings are loaded (SDK isolation mode)."
 *
 * That means the SDK does NOT load ~/.claude/settings.json by default — and plugins
 * are configured there. So we run the probe twice:
 *   1. Default (SDK isolation) — expected: hooks do NOT fire.
 *   2. settingSources: ['user'] — this is the explicit opt-in that should load
 *      the user's plugin config. If hooks fire here, the SDK IS hook-capable
 *      and the benchmark harness can be ported.
 */

import { query, type SDKMessage, type Options } from "@anthropic-ai/claude-agent-sdk";
import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";

const __dirname = dirname(fileURLToPath(import.meta.url));

const PROMPT =
  "Let's switch from JWT to opaque tokens because of revocation requirements — record this decision.";

function getSdkVersion(): string {
  try {
    const pkgPath = join(
      __dirname,
      "node_modules",
      "@anthropic-ai",
      "claude-agent-sdk",
      "package.json",
    );
    const pkg = JSON.parse(readFileSync(pkgPath, "utf8")) as { version?: string };
    return pkg.version ?? "unknown";
  } catch (error: unknown) {
    return `unreadable (${error instanceof Error ? error.message : String(error)})`;
  }
}

interface RunResult {
  modeLabel: string;
  messagesReceived: number;
  assistantTextSnippet: string;
  finalSubtype: string | undefined;
  durationMs: number;
  errored: boolean;
  errorMessage?: string;
}

async function runOneQuery(modeLabel: string, options: Options): Promise<RunResult> {
  const startedAt = Date.now();
  const result: RunResult = {
    modeLabel,
    messagesReceived: 0,
    assistantTextSnippet: "",
    finalSubtype: undefined,
    durationMs: 0,
    errored: false,
  };

  try {
    const q = query({ prompt: PROMPT, options });
    for await (const msg of q as AsyncIterable<SDKMessage>) {
      result.messagesReceived += 1;

      // Capture a tiny slice of the assistant text so we can prove it actually responded.
      if (msg.type === "assistant" && result.assistantTextSnippet === "") {
        const content = msg.message?.content;
        if (Array.isArray(content)) {
          for (const block of content) {
            if (block && typeof block === "object" && "type" in block && block.type === "text") {
              const text = (block as { text?: unknown }).text;
              if (typeof text === "string" && text.length > 0) {
                result.assistantTextSnippet = text.slice(0, 120);
                break;
              }
            }
          }
        }
      }

      if (msg.type === "result") {
        result.finalSubtype = (msg as { subtype?: string }).subtype;
      }
    }
  } catch (error: unknown) {
    result.errored = true;
    result.errorMessage = error instanceof Error ? error.message : String(error);
  }

  result.durationMs = Date.now() - startedAt;
  return result;
}

function printRun(r: RunResult): void {
  console.log(`--- run: ${r.modeLabel} ---`);
  console.log(`  duration:           ${(r.durationMs / 1000).toFixed(2)}s`);
  console.log(`  messages received:  ${r.messagesReceived}`);
  console.log(`  final subtype:      ${r.finalSubtype ?? "(none)"}`);
  console.log(`  assistant snippet:  ${r.assistantTextSnippet || "(empty)"}`);
  if (r.errored) {
    console.log(`  ERROR:              ${r.errorMessage}`);
  }
  console.log("");
}

async function main(): Promise<void> {
  console.log("=== SDK probe ===");
  console.log(`SDK package:  @anthropic-ai/claude-agent-sdk`);
  console.log(`SDK version:  ${getSdkVersion()}`);
  console.log(`cwd:          ${process.cwd()}`);
  console.log(`entry point:  query() from sdk.mjs (default export "@anthropic-ai/claude-agent-sdk")`);
  console.log("");
  console.log(`prompt:       ${PROMPT}`);
  console.log("");

  // Run 1: SDK default (isolation mode). No filesystem settings loaded.
  console.log(">>> Run 1: SDK default options (no settingSources => isolation mode)");
  console.log(">>> Expectation: user's ~/.claude/settings.json (and therefore plugins/hooks) NOT loaded.");
  console.log("");
  const isolationRun = await runOneQuery("isolation (defaults)", {
    cwd: process.cwd(),
  });
  printRun(isolationRun);

  // Run 2: explicit settingSources: ['user'] — load user-scope settings, which
  // includes the enabled claude-mind plugin and its hooks.
  console.log(">>> Run 2: settingSources: ['user'] (load user-scope settings)");
  console.log(">>> Expectation: claude-mind plugin's hooks SHOULD fire (if SDK supports them).");
  console.log("");
  const userSettingsRun = await runOneQuery("settingSources=['user']", {
    cwd: process.cwd(),
    settingSources: ["user"],
  });
  printRun(userSettingsRun);

  console.log("=== probe done ===");
  console.log("Now let run.sh wait 30s for any async hook subprocesses, then check ./brain/.");
}

main().catch((error: unknown) => {
  console.error("probe.ts: unexpected top-level failure:", error);
  process.exit(1);
});
