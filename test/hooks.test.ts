// test/hooks.test.ts
import { describe, expect, test, beforeEach, afterEach } from "bun:test";
import { existsSync, mkdirSync, mkdtempSync, readFileSync, rmSync } from "node:fs";
import { join } from "node:path";
import { tmpdir } from "node:os";
import { spawnSync } from "node:child_process";

const HOOK_DIR = join(import.meta.dir, "..", "hooks");
const FIXTURE_DIR = join(import.meta.dir, "fixtures");

describe("stop.sh", () => {
  let tmp: string;

  beforeEach(() => {
    tmp = mkdtempSync(join(tmpdir(), "sc-test-"));
    mkdirSync(join(tmp, "brain"));
  });

  afterEach(() => {
    rmSync(tmp, { recursive: true, force: true });
  });

  test("appends to ./brain/_journal.md when transcript present", () => {
    const result = spawnSync("bash", [join(HOOK_DIR, "stop.sh")], {
      cwd: tmp,
      env: {
        ...process.env,
        CLAUDE_TRANSCRIPT_PATH: join(FIXTURE_DIR, "transcript-minimal.txt"),
        CLAUDE_PLUGIN_ROOT: join(import.meta.dir, ".."),
        // Force the fake-claude shim so test doesn't call the real CLI:
        PATH: `${join(import.meta.dir, "fixtures", "bin")}:${process.env.PATH}`,
      },
    });

    expect(result.status).toBe(0);
    expect(existsSync(join(tmp, "brain", "_journal.md"))).toBe(true);
    const journal = readFileSync(join(tmp, "brain", "_journal.md"), "utf8");
    expect(journal).toContain("[fake-claude-output]");
  });

  test("exits 0 silently if no ./brain/ directory", () => {
    rmSync(join(tmp, "brain"), { recursive: true });
    const result = spawnSync("bash", [join(HOOK_DIR, "stop.sh")], {
      cwd: tmp,
      env: { ...process.env, CLAUDE_TRANSCRIPT_PATH: join(FIXTURE_DIR, "transcript-minimal.txt") },
    });
    expect(result.status).toBe(0);
  });

  test("exits 0 silently if claude CLI missing", () => {
    const result = spawnSync("bash", [join(HOOK_DIR, "stop.sh")], {
      cwd: tmp,
      // PATH includes /bin and /usr/bin so bash itself resolves, but excludes
      // test/fixtures/bin so the fake `claude` shim is unreachable.
      env: { ...process.env, CLAUDE_TRANSCRIPT_PATH: join(FIXTURE_DIR, "transcript-minimal.txt"), PATH: "/bin:/usr/bin" },
    });
    expect(result.status).toBe(0);
  });
});

describe("pre-tool-use.sh", () => {
  let tmp: string;

  beforeEach(() => {
    tmp = mkdtempSync(join(tmpdir(), "sc-pre-"));
  });

  afterEach(() => {
    rmSync(tmp, { recursive: true, force: true });
  });

  test("warns when tool is Edit and no <thinking> in recent context", () => {
    const transcript = "User: do the thing\nAssistant: ok let me read the file";
    const transcriptFile = join(tmp, "transcript.txt");
    require("node:fs").writeFileSync(transcriptFile, transcript);

    const result = spawnSync("bash", [join(HOOK_DIR, "pre-tool-use.sh")], {
      cwd: tmp,
      env: { ...process.env, CLAUDE_TRANSCRIPT_PATH: transcriptFile, CLAUDE_TOOL_NAME: "Edit" },
    });
    expect(result.status).toBe(0); // never blocks
    expect(result.stderr.toString()).toContain("think-first");
  });

  test("silent when <thinking> present in recent context", () => {
    const transcript = "User: do the thing\nAssistant: <thinking>plan</thinking>\nlet's edit";
    const transcriptFile = join(tmp, "transcript.txt");
    require("node:fs").writeFileSync(transcriptFile, transcript);

    const result = spawnSync("bash", [join(HOOK_DIR, "pre-tool-use.sh")], {
      cwd: tmp,
      env: { ...process.env, CLAUDE_TRANSCRIPT_PATH: transcriptFile, CLAUDE_TOOL_NAME: "Edit" },
    });
    expect(result.status).toBe(0);
    expect(result.stderr.toString()).not.toContain("think-first");
  });

  test("silent for read-only tools", () => {
    const result = spawnSync("bash", [join(HOOK_DIR, "pre-tool-use.sh")], {
      cwd: tmp,
      env: { ...process.env, CLAUDE_TOOL_NAME: "Read" },
    });
    expect(result.status).toBe(0);
    expect(result.stderr.toString()).toBe("");
  });
});
