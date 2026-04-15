// test/skills.test.ts
import { describe, expect, test } from "bun:test";
import { existsSync, readdirSync, readFileSync, statSync } from "node:fs";
import { join } from "node:path";
import matter from "gray-matter";

const SKILLS_DIR = join(import.meta.dir, "..", "skills");
const REQUIRED_FIELDS = ["name", "description"] as const;
const MIN_BODY_WORDS = 100;

function listSkills(): string[] {
  if (!existsSync(SKILLS_DIR)) return [];
  return readdirSync(SKILLS_DIR).filter((entry) => {
    const full = join(SKILLS_DIR, entry);
    return statSync(full).isDirectory();
  });
}

describe("skills", () => {
  test("at least one skill exists", () => {
    expect(listSkills().length).toBeGreaterThan(0);
  });

  for (const skill of listSkills()) {
    describe(skill, () => {
      const skillPath = join(SKILLS_DIR, skill, "SKILL.md");

      test("has SKILL.md", () => {
        expect(existsSync(skillPath)).toBe(true);
      });

      test.each(REQUIRED_FIELDS)("frontmatter has %s", (field) => {
        if (!existsSync(skillPath)) throw new Error(`SKILL.md missing at ${skillPath}`);
        const { data } = matter(readFileSync(skillPath, "utf8"));
        expect(data[field]).toBeTruthy();
      });

      test(`body has at least ${MIN_BODY_WORDS} words`, () => {
        if (!existsSync(skillPath)) throw new Error(`SKILL.md missing at ${skillPath}`);
        const { content } = matter(readFileSync(skillPath, "utf8"));
        const trimmed = content.trim();
        const wordCount = trimmed === "" ? 0 : trimmed.split(/\s+/).length;
        expect(wordCount).toBeGreaterThanOrEqual(MIN_BODY_WORDS);
      });
    });
  }

  test("RESOLVER.md exists and references every skill", () => {
    const resolverPath = join(SKILLS_DIR, "RESOLVER.md");
    expect(existsSync(resolverPath)).toBe(true);
    const resolver = readFileSync(resolverPath, "utf8");
    for (const skill of listSkills()) {
      expect(resolver).toContain(skill);
    }
  });
});
