/**
 * Content collections.
 *
 * Articles are *not* here: every published article is a Typst note compiled
 * from `blog.toml` into `src/generated/` (see `src/lib/notes.ts`). Markdown
 * survives only for standalone pages such as `/about`.
 */
import { defineCollection } from "astro:content";
import { z } from "astro/zod";
import { glob } from "astro/loaders";

const pages = defineCollection({
  loader: glob({ pattern: "**/[^_]*.{md,mdx}", base: "./src/content/pages" }),
  schema: z.object({
    title: z.string(),
    description: z.string().optional(),
    ogImage: z.string().optional(),
    canonicalURL: z.string().optional(),
  }),
});

export const collections = { pages };
