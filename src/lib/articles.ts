/**
 * Unified reading model for the site.
 *
 * Notes (Typst) and posts (Markdown) are stored and rendered differently, but
 * that is an implementation detail. Readers only care that everything is an
 * article, so every listing page (home, /posts, tags, archives, RSS) works from
 * this shared shape.
 */
import { getCollection } from "astro:content";
import { getRelativeLocaleUrl } from "astro:i18n";
import config from "@/config";
import { notes, projects, projectOf, type Project } from "@/lib/notes";
import { getPostUrl } from "@/utils/getPostPaths";
import { postFilter } from "@/utils/postFilter";
import { slugifyStr } from "@/utils/slugify";

export interface Article {
  id: string;
  title: string;
  description: string;
  date: Date | null;
  tags: string[];
  featured: boolean;
  /**
   * Position within its project, from `blog.toml`; lower comes first. This is
   * the primary sort key of every listing — date only breaks ties. Articles
   * without a declared order (Markdown posts) sort after all ordered ones.
   */
  order?: number;
  /** Present when the article belongs to a project (all notes do). */
  project?: Project;
  /** Fully localized, base-aware URL. */
  href: string;
  /** Internal only; never expose this distinction in the UI. */
  kind: "post" | "note";
}

export interface ArticleGroup {
  project: Project;
  articles: Article[];
}

export interface ArticleTag {
  tag: string;
  tagName: string;
}

const FALLBACK_PROJECT_ORDER = 999;

/** Sort key for articles that declare no `order` (all Markdown posts). */
const NO_ORDER = Number.MAX_SAFE_INTEGER;

function projectById(id: string): Project {
  return (
    projects.find(project => project.id === id) ?? {
      id,
      title: id,
      description: "",
      order: FALLBACK_PROJECT_ORDER,
    }
  );
}

function noteDate(date: string | null): Date | null {
  return date ? new Date(`${date}T00:00:00Z`) : null;
}

/**
 * Returns every published post plus every compiled note, ordered by `order`
 * (lower first) and then newest first.
 *
 * `order` is deliberately the *primary* key rather than the date: the curated
 * `blog.toml` listing is the source of truth for reading order, so a note with
 * a small `order` stays on top even after its date is bumped.
 *
 * Notes have no draft/scheduled state in the manifest, so all of them are
 * included. Posts still respect `postFilter()`.
 */
export async function getAllArticles(
  locale: string = config.site.lang
): Promise<Article[]> {
  const posts = await getCollection("posts");

  const postArticles: Article[] = posts.filter(postFilter).map(post => ({
    id: post.id,
    title: post.data.title,
    description: post.data.description,
    date: post.data.modDatetime ?? post.data.pubDatetime,
    tags: post.data.tags,
    featured: post.data.featured ?? false,
    order: post.data.order,
    project: post.data.project ? projectById(post.data.project) : undefined,
    href: getPostUrl(post.id, post.filePath, locale),
    kind: "post",
  }));

  const noteArticles: Article[] = notes.map(note => ({
    id: note.slug,
    title: note.title,
    description: note.summary,
    date: noteDate(note.date),
    tags: note.tags,
    featured: false,
    order: note.order,
    project: projectOf(note),
    href: getRelativeLocaleUrl(locale, `posts/${note.slug}`),
    kind: "note",
  }));

  return [...postArticles, ...noteArticles].sort((a, b) => {
    // 1. curated order, ascending ("lower first")
    const orderDelta = (a.order ?? NO_ORDER) - (b.order ?? NO_ORDER);
    if (orderDelta !== 0) return orderDelta;

    // 2. same order (or both unordered): newest first
    const aTime = a.date?.getTime() ?? Number.NEGATIVE_INFINITY;
    const bTime = b.date?.getTime() ?? Number.NEGATIVE_INFINITY;
    if (aTime !== bTime) return bTime - aTime;

    // 3. fully tied: keep the output deterministic
    return a.id.localeCompare(b.id);
  });
}

/** Groups articles by their project, preserving the manifest project order. */
export function groupArticlesByProject(articles: Article[]): ArticleGroup[] {
  const groups = new Map<string, ArticleGroup>();

  for (const article of articles) {
    if (!article.project) continue;

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

/** De-duplicated tag list across every article (posts and notes). */
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
