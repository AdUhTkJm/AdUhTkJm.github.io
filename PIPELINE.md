# How this blog is built

A notes-first static site. Technical content is **not rewritten here**: the pages
under `/notes/` are compiled from Typst snapshots of documents that live in the
project repos.

## What is committed, and why

| Committed | Not committed |
|---|---|
| `blog.toml` — the allowlist | `src/generated/` — compiled HTML |
| `sources/<slug>.typ` — a snapshot per note | `public/pdf/` — compiled PDFs |
| `sources/provenance.json` — upstream commit per snapshot | `.tools/` — the typst binary |

The snapshot is the **only build input**. `scripts/compile.py` always compiles
`sources/<slug>.typ`, never the live project file, which buys three things:

1. **Nothing generated is versioned.** No 700 KB PDFs in history, no HTML that
   is redundant with a pinned compiler and a self-contained source.
2. **A fresh clone builds identically on a machine that has none of the
   projects.** Verified byte-for-byte: same HTML, same PDF, from a clone with
   `$HOME` pointing at a directory with no `~/projects`.
3. **CI needs no access to the project repositories** and no secrets.

The cost is that a build now needs typst (a ~40 MB download, cached) instead of
just Node.

```
blog.toml                         curated allowlist: which docs get published
sources/<slug>.typ                snapshot of each published document (the input)
sources/provenance.json           which upstream commit each snapshot came from
scripts/compile.py                snapshot -> HTML (MathML) + PDF
compile.sh                        the only command you run
src/lib/notes.ts                  typed accessors for the generated manifest
src/pages/notes/                  index + [...slug].astro renderer
src/styles/note.css               screen typography that mirrors the PDF
```

## Daily use

```sh
./compile.sh          # refresh snapshots, compile, build
./compile.sh --dev    # same, then `astro dev`
./compile.sh --check  # are the snapshots still in sync with the live docs?
```

`compile.sh` is a thin wrapper over `pnpm build`, and `pnpm build` runs
`scripts/compile.py` first — so the pipeline cannot be skipped by calling pnpm
directly. The first run downloads a pinned `typst` into `.tools/`; your system
`typst` is never used, so its version does not matter.

Enable the safety net once per clone:

```sh
git config --local core.hooksPath .githooks
```

Now `git push` refuses to push a snapshot that no longer matches its source.

## Adding a note

1. Write or edit the document in its project repo (e.g.
   `~/projects/seedsearch/docs/optimizations.typ`).
2. Add a `[[note]]` block to `blog.toml` (or edit the existing one).
3. `./compile.sh` — this copies the document into `sources/`, records its
   commit in `sources/provenance.json`, and builds.
4. Commit `blog.toml` and `sources/`.

The document's own title block and page setup are ignored by the HTML exporter;
`title`, `summary`, `date` and `tags` come from `blog.toml`.

A snapshot must be **self-contained**: `#import "other.typ"` would not be
snapshotted, so `compile.py` fails loudly if it finds a relative import or
include. Packages (`@preview/cuti`, `@preview/cetz`) are fine — they resolve
from Typst Universe at build time.

## Why Typst exports HTML directly

Typst 0.15 exports equations to **MathML**, tables to `<table>`, cross-references
to anchors and footnotes to `role="doc-endnotes"`. So there is no
Typst → Markdown → LaTeX conversion to maintain, and no KaTeX bundle on the page.

Two things to know:

- **Math is only exported from 0.15 onwards.** On 0.14 equations are silently
  dropped. `compile.py` fails loudly if a source contains `$` but the output has
  no `<math>`, so a wrong typst version cannot slip through.
- **`--features html` is officially unstable.** Hence the pinned version in
  `blog.toml`; upgrading typst is a deliberate act. Review it by comparing the
  rendered site (or `sources/` + the old/new compiler) rather than a diff of
  generated HTML, which is no longer tracked.

Paged-only rules (`page`, `align`, page breaks) are ignored in HTML — which is
why the same source is *also* compiled to PDF.

## Interactive widgets and diagrams

- Diagrams drawn in Typst need wrapping: `html.frame(canvas(...))` renders
  inline SVG. A bare `cetz` canvas is **silently dropped** by the HTML exporter.
- A Typst document can leave a mount point for JavaScript:

  ```typst
  #html.elem("div", attrs: (class: "widget", "data-widget": "rng-stream"))
  ```

  A client script can then hydrate every `[data-widget]`. Not implemented yet —
  there are no widgets in the skeleton.

## Deploying

`.github/workflows/deploy.yml` runs `pnpm build` (which compiles the snapshots)
and publishes `dist/`. In the GitHub repo: **Settings → Pages → Source: GitHub
Actions**.

Two CI details:

- **`fonts-noto-cjk` is installed in CI.** HTML output is font-independent —
  verified: byte-identical with system fonts suppressed — but PDF output is not.
  Without a CJK font, typst falls back to a Latin face and Chinese becomes tofu.
  `Libertinus Serif` needs no install; it ships inside the typst binary.
- **`.tools/` is cached** by a key derived from `blog.toml`, so the typst
  download only happens when the pinned version changes.

- Project site (repo `blogs`, URL `/<user>.github.io>/blogs/`): `base = "/blogs"`.
- User site (repo `<user>.github.io`): set `base = "/"` in both `blog.toml` and
  `astro-paper.config.ts`.

## Pitfalls (learned the hard way)

**Never set `display` on `<math>`.** The UA stylesheet gives `math[display=block]`
the value `block math`; the `math` half is what makes MathML lay out its
children. Overriding it with `display: block` turns `mi`, `mo`, `mfrac` into
ordinary block boxes and the equation collapses into a single vertical column of
symbols. This is why `compile.py` wraps display equations in
`<div class="math-block">` — scrolling needs a block-level box, but it must be
the *wrapper*, never the `math` itself.

**Tables need both `code { white-space: nowrap }` and a cell floor.** Without
`nowrap`, identifiers split mid-token (`NextUnsignedInt(m` / `in,max)`). With
`nowrap` alone, the table's min-content exceeds the column and the browser
crushes the CJK prose column to one character per line — so `td`/`th` also get
`min-width: 4em` and `.table-wrap` scrolls instead.

**`text-muted` is a background colour, not a text colour.** The theme exposes
`--muted` (#e6e6e6) for backgrounds and `--muted-foreground` (#6b7280) for text.
Using `text-muted` gives near-invisible grey-on-white.

**Deep links are smooth-scrolled.** `scroll-smooth` is on `<html>`, so a hash
link into a 13,000 px document animates for ~2 s before arriving. Correct, just
slow; remove `scroll-smooth` if it bothers you.

## Verifying visually

The layout was checked with headless Chromium, not by eye. To repeat it:

```sh
./compile.sh && pnpm preview        # then use the printed URL
```

Useful invariants to assert: display equations should have
`getComputedStyle(m).display === "block math"` and children spread across
multiple `x` positions; no `td` narrower than ~3em; and
`document.documentElement.scrollWidth === innerWidth` on a 390 px viewport.

## Known gaps

| Gap | Notes |
|---|---|
| Markdown sources | `compile.py` only handles `.typ` for now; `.md` docs (e.g. the llama.cpp one) need a pass-through path into a content collection. |
| CJK fonts on the site | The site relies on system serif fonts for Chinese instead of shipping a ~8 MB Noto CJK webfont. (PDFs are unaffected: CI installs the font.) |
| OG images | `dynamicOgImage` is off: satori's bundled font has no CJK glyphs. |
| `search` | Pagefind indexes `/notes/` pages (`data-pagefind-body`), but has no Chinese stemming. |
| No widgets yet | The island pipeline is set up (Astro), nothing uses it. |
| Deleted demo posts | The AstroPaper sample posts were removed; `src/content/posts/hello.md` is the only post. |

## Upgrading typst

1. Change `[typst] version` in `blog.toml`.
2. `rm .tools/typst.version` (forces re-download; also busts the CI cache key).
3. `./compile.sh` and read the console warnings, then look at the rendered page
   and the PDF. Since generated output is no longer versioned, there is no diff
   to review — the compiler version is the contract.
