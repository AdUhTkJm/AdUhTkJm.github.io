/**
 * Access to the output of `scripts/compile.py`.
 *
 * `src/generated/notes.json` is the manifest (metadata + table of contents) and
 * `src/generated/notes/<slug>.html` holds the page body produced by Typst.
 * Both are committed; run `./compile.sh` after editing blog.toml.
 */
import manifest from "@/generated/notes.json";

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

/** Notes grouped by project, in manifest order. */
export function groupedNotes(): { project: Project; notes: Note[] }[] {
  return projects
    .map(project => ({
      project,
      notes: notes.filter(n => n.project === project.id),
    }))
    .filter(group => group.notes.length > 0);
}

/** Short display form of a source commit, e.g. "aw@422b903". */
export function sourceLabel(note: Note): string {
  const commit = note.source.commit;
  if (!commit) return note.source.declared;
  return `${note.project}@${commit}${note.source.dirty ? " (modified)" : ""}`;
}
