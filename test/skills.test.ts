// test/skills.test.ts
import { describe, expect, test } from "bun:test";
import { readdirSync, readFileSync, statSync } from "node:fs";
import { join } from "node:path";
import matter from "gray-matter";

const SKILLS_DIR = join(import.meta.dir, "..", "skills");
const REQUIRED_FIELDS = ["name", "description"] as const;
const MIN_BODY_WORDS = 100;

function listSkills(): string[] {
  return readdirSync(SKILLS_DIR)
    .filter((entry) => {
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
      const raw = readFileSync(skillPath, "utf8");
      const { data, content } = matter(raw);

      test("has SKILL.md", () => {
        expect(raw.length).toBeGreaterThan(0);
      });

      test.each(REQUIRED_FIELDS)("frontmatter has %s", (field) => {
        expect(data[field]).toBeTruthy();
      });

      test(`body has at least ${MIN_BODY_WORDS} words`, () => {
        const wordCount = content.trim().split(/\s+/).length;
        expect(wordCount).toBeGreaterThanOrEqual(MIN_BODY_WORDS);
      });
    });
  }

  test("RESOLVER.md exists and references every skill", () => {
    const resolverPath = join(SKILLS_DIR, "RESOLVER.md");
    const resolver = readFileSync(resolverPath, "utf8");
    for (const skill of listSkills()) {
      expect(resolver).toContain(skill);
    }
  });
});
