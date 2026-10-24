/**
 * Access to the output of `scripts/compile.py`.
 *
 * `src/generated/notes.json` is the manifest (metadata + table of contents) and
 * `src/generated/notes/<slug>.html` holds the page body produced by Typst.
 * Neither is committed; run `./compile.sh` after editing blog.toml.
 *
 * Figures drawn in Typst arrive as inline `<svg>`; raster `#image(...)`s are
 * pulled out to `public/images/<slug>/` by the same script and referenced by
 * URL from inside the body.
 */
import manifest from "@/generated/notes.json";
import { htmlWordCount } from "@/utils/wordCount";

export interface TocEntry {
  level: number;
  text: string;
  id: string;
}

export interface Note {
  slug: string;
  title: string;
  summary: string;
  tags: string[];
  date: string | null;
  order: number;
  project: string;
  kind: string;
  html: string;
  pdf: string;
  source: { declared: string; commit: string | null; dirty: boolean };
  snapshot: string;
  bytes: number;
  math: number;
  figures: number;
  images: number;
  toc: TocEntry[];
}

export interface Project {
  id: string;
  title: string;
  description: string;
  order: number;
}

interface Manifest {
  typstVersion: string;
  site: Record<string, string>;
  projects: Project[];
  notes: Note[];
}

const data = manifest as unknown as Manifest;

export const notes: Note[] = data.notes;
export const projects: Project[] = data.projects;
export const typstVersion: string = data.typstVersion;

/** Body HTML for a note, injected verbatim into the page. */
const rawBodies = import.meta.glob<string>("../generated/notes/**/*.html", {
  query: "?raw",
  import: "default",
  eager: true,
});

const bodies = new Map<string, string>();
for (const [key, body] of Object.entries(rawBodies)) {
  const slug = key
    .replace(/^.*\/generated\/notes\//, "")
    .replace(/\.html$/, "");
  bodies.set(slug, body);
}

export function noteBody(slug: string): string {
  const body = bodies.get(slug);
  if (!body) {
    throw new Error(
      `No generated HTML for "${slug}". Run ./compile.sh (or check blog.toml).`
    );
  }
  return body;
}

const wordCounts = new Map<string, number>();

/**
 * Prose length of a note: CJK characters plus Latin words, with code blocks and
 * equations left out (see `@/utils/wordCount`). Computed from the generated
 * HTML once per build, then cached by slug.
 */
export function noteWords(note: Note): number {
  const cached = wordCounts.get(note.slug);
  if (cached !== undefined) return cached;

  const words = htmlWordCount(noteBody(note.slug));
  wordCounts.set(note.slug, words);
  return words;
}

export function projectOf(note: Note): Project {
  return (
    projects.find(p => p.id === note.project) ?? {
      id: note.project,
      title: note.project,
      description: "",
      order: 999,
    }
  );
}

/** Short display form of a source commit, e.g. "aw@422b903". */
export function sourceLabel(note: Note): string {
  const commit = note.source.commit;
  if (!commit) return note.source.declared;
  return `${note.project}@${commit}${note.source.dirty ? " (modified)" : ""}`;
}
