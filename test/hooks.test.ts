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
    const stdinJson = JSON.stringify({
      session_id: "test",
      transcript_path: join(FIXTURE_DIR, "transcript-minimal.txt"),
      cwd: tmp,
    });
    const result = spawnSync("bash", [join(HOOK_DIR, "stop.sh")], {
      cwd: tmp,
      input: stdinJson,
      env: {
        ...process.env,
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
    const stdinJson = JSON.stringify({
      session_id: "test",
      transcript_path: join(FIXTURE_DIR, "transcript-minimal.txt"),
      cwd: tmp,
    });
    const result = spawnSync("bash", [join(HOOK_DIR, "stop.sh")], {
      cwd: tmp,
      input: stdinJson,
      env: { ...process.env },
    });
    expect(result.status).toBe(0);
  });

  test("exits 0 silently if claude CLI missing", () => {
    const stdinJson = JSON.stringify({
      session_id: "test",
      transcript_path: join(FIXTURE_DIR, "transcript-minimal.txt"),
      cwd: tmp,
    });
    const result = spawnSync("bash", [join(HOOK_DIR, "stop.sh")], {
      cwd: tmp,
      input: stdinJson,
      // PATH includes /bin and /usr/bin so bash itself resolves, but excludes
      // test/fixtures/bin so the fake `claude` shim is unreachable.
      env: { ...process.env, PATH: "/bin:/usr/bin" },
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

    const stdinJson = JSON.stringify({
      session_id: "test",
      tool_name: "Edit",
      transcript_path: transcriptFile,
      cwd: tmp,
    });
    const result = spawnSync("bash", [join(HOOK_DIR, "pre-tool-use.sh")], {
      cwd: tmp,
      input: stdinJson,
      env: { ...process.env },
    });
    expect(result.status).toBe(0); // never blocks
    expect(result.stderr.toString()).toContain("think-first");
  });

  test("silent when <thinking> present in recent context", () => {
    const transcript = "User: do the thing\nAssistant: <thinking>plan</thinking>\nlet's edit";
    const transcriptFile = join(tmp, "transcript.txt");
    require("node:fs").writeFileSync(transcriptFile, transcript);

    const stdinJson = JSON.stringify({
      session_id: "test",
      tool_name: "Edit",
      transcript_path: transcriptFile,
      cwd: tmp,
    });
    const result = spawnSync("bash", [join(HOOK_DIR, "pre-tool-use.sh")], {
      cwd: tmp,
      input: stdinJson,
      env: { ...process.env },
    });
    expect(result.status).toBe(0);
    expect(result.stderr.toString()).not.toContain("think-first");
  });

  test("silent for read-only tools", () => {
    const stdinJson = JSON.stringify({
      session_id: "test",
      tool_name: "Read",
      cwd: tmp,
    });
    const result = spawnSync("bash", [join(HOOK_DIR, "pre-tool-use.sh")], {
      cwd: tmp,
      input: stdinJson,
      env: { ...process.env },
    });
    expect(result.status).toBe(0);
    expect(result.stderr.toString()).toBe("");
  });
});

describe("user-prompt-submit.sh", () => {
  let tmp: string;

  beforeEach(() => {
    tmp = mkdtempSync(join(tmpdir(), "sc-ups-"));
    mkdirSync(join(tmp, "brain"));
  });

  afterEach(() => {
    rmSync(tmp, { recursive: true, force: true });
  });

  test("returns immediately (non-blocking) and spawns subprocess", () => {
    const start = Date.now();
    const result = spawnSync("bash", [join(HOOK_DIR, "user-prompt-submit.sh")], {
      cwd: tmp,
      input: "Let's switch from JWT to opaque tokens",
      env: {
        ...process.env,
        CLAUDE_PLUGIN_ROOT: join(import.meta.dir, ".."),
        PATH: `${join(import.meta.dir, "fixtures", "bin")}:${process.env.PATH}`,
      },
    });
    const elapsed = Date.now() - start;
    expect(result.status).toBe(0);
    expect(elapsed).toBeLessThan(1000); // returns fast; doesn't wait for subprocess
  });

  test("exits 0 silently when ./brain/ missing", () => {
    rmSync(join(tmp, "brain"), { recursive: true });
    const result = spawnSync("bash", [join(HOOK_DIR, "user-prompt-submit.sh")], {
      cwd: tmp,
      input: "anything",
      env: { ...process.env },
    });
    expect(result.status).toBe(0);
  });
});
