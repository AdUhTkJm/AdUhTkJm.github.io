/**
 * Unified reading model for the site.
 *
 * Every published article is a Typst note compiled from `blog.toml` into
 * `src/generated/` (see `src/lib/notes.ts`). Listings never touch the manifest
 * directly: they work from the `Article` shape below, so the home page,
 * `/posts`, tags, archives and RSS all agree on ordering and URLs.
 */
import { getRelativeLocaleUrl } from "astro:i18n";
import config from "@/config";
import { notes, projectOf, type Project } from "@/lib/notes";
import { slugifyStr } from "@/utils/slugify";

export interface Article {
  id: string;
  title: string;
  description: string;
  date: Date | null;
  tags: string[];
  /**
   * Listing position from `blog.toml`; lower comes first. This is the primary
   * sort key of every listing — the date only breaks ties.
   */
  order: number;
  project: Project;
  /** Fully localized, base-aware URL. */
  href: string;
}

export interface ArticleGroup {
  project: Project;
  articles: Article[];
}

export interface ArticleTag {
  tag: string;
  tagName: string;
}

function noteDate(date: string | null): Date | null {
  return date ? new Date(`${date}T00:00:00Z`) : null;
}

/**
 * Returns every published note, ordered by `order` (lower first) and then
 * newest first.
 *
 * `order` is deliberately the *primary* key rather than the date: the curated
 * `blog.toml` listing is the source of truth for reading order, so a note with
 * a small `order` stays on top even after its date is bumped.
 *
 * Notes have no draft/scheduled state in the manifest, so all of them are
 * included.
 */
export async function getAllArticles(
  locale: string = config.site.lang
): Promise<Article[]> {
  const articles: Article[] = notes.map(note => ({
    id: note.slug,
    title: note.title,
    description: note.summary,
    date: noteDate(note.date),
    tags: note.tags,
    order: note.order,
    project: projectOf(note),
    href: getRelativeLocaleUrl(locale, `posts/${note.slug}`),
  }));

  return articles.sort((a, b) => {
    // 1. curated order, ascending ("lower first")
    if (a.order !== b.order) return a.order - b.order;

    // 2. same order: newest first
    const aTime = a.date?.getTime() ?? Number.NEGATIVE_INFINITY;
    const bTime = b.date?.getTime() ?? Number.NEGATIVE_INFINITY;
    if (aTime !== bTime) return bTime - aTime;

    // 3. fully tied: keep the output deterministic
    return a.id.localeCompare(b.id);
  });
}

/** Groups articles by their project, in manifest project order. */
export function groupArticlesByProject(articles: Article[]): ArticleGroup[] {
  const groups = new Map<string, ArticleGroup>();

  for (const article of articles) {
    const group = groups.get(article.project.id);
    if (group) {
      group.articles.push(article);
    } else {
      groups.set(article.project.id, {
        project: article.project,
        articles: [article],
      });
    }
  }

  return [...groups.values()].sort(
    (a, b) =>
      a.project.order - b.project.order ||
      a.project.title.localeCompare(b.project.title)
  );
}

/** De-duplicated tag list across every article. */
export function getUniqueArticleTags(articles: Article[]): ArticleTag[] {
  const tags = new Map<string, string>();

  for (const article of articles) {
    for (const tag of article.tags) {
      const slug = slugifyStr(tag);
      if (!tags.has(slug)) tags.set(slug, tag);
    }
  }

  return [...tags.entries()]
    .map(([tag, tagName]) => ({ tag, tagName }))
    .sort((a, b) => a.tag.localeCompare(b.tag));
}

/** Whether an article carries a given (already slugified) tag. */
export function hasTag(article: Article, tag: string): boolean {
  return article.tags.some(articleTag => slugifyStr(articleTag) === tag);
}
