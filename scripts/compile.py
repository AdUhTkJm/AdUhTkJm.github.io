#!/usr/bin/env python3
"""Compile the curated notes in blog.toml into web pages.

The only committed inputs are `blog.toml` and the snapshots under `sources/`.
Both the site build and CI compile **from the snapshot**, never from the live
project checkout, so:

  - a fresh clone builds identically without the project repositories;
  - nothing generated is committed (no HTML, no PDFs in git);
  - the build input is exactly the files you can read in `sources/`.

A note comes in one of two shapes:

  single file   `source = "~/projects/x/docs/page.typ"` -> `sources/<slug>.typ`
  directory     `source = "~/llvm/dissertation"`        -> `sources/<slug>/...`
                with `entry = "web.typ"` naming the root .typ inside it

The directory shape exists for documents that are split across files
(`#include` / `#import` / `#image`). The whole tree is snapshotted, because a
snapshot is only reproducible if nothing outside it is needed.

For every [[note]] entry (skipped when the previous build's inputs are
unchanged — see the build-cache section below):

    sources/<slug>.typ      ->  src/generated/notes/<slug>.html   HTML + MathML
    sources/<slug>/<entry>  ->  public/images/<slug>/*.png        extracted figures
                            ->  public/pdf/<slug>.pdf             paged A4

`--check` verifies that the committed snapshots still match the live sources, so
a stale snapshot cannot be pushed. `--no-cache` ignores cached artifacts.
"""

from __future__ import annotations

import argparse
import base64
import fnmatch
import hashlib
import json
import mimetypes
import os
import platform
import re
import shutil
import subprocess
import sys
import tarfile
import tempfile
import tomllib
import urllib.request
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
MANIFEST = ROOT / "blog.toml"
TOOLS = ROOT / ".tools"
CACHE_DIR = ROOT / ".cache" / "notes"
NOTES_DIR = ROOT / "src" / "generated" / "notes"
NOTES_JSON = ROOT / "src" / "generated" / "notes.json"
PDF_DIR = ROOT / "public" / "pdf"
IMAGE_DIR = ROOT / "public" / "images"
SNAPSHOT_DIR = ROOT / "sources"
PROVENANCE = SNAPSHOT_DIR / "provenance.json"

# typst CLI flags that turn on the experimental HTML exporter.
HTML_FLAGS = ["--features", "html"]

# Reproducible output: without this, every PDF embeds a creation date.
REPRO_ENV = {**os.environ, "SOURCE_DATE_EPOCH": "0"}

# Where the diagram shim is written inside the throwaway build tree. Only ever
# created under a temp dir, never inside sources/.
SHIM_DIR = "_blog_shim"

# Never part of a snapshot, no matter what the manifest says.
#
# `.gitignore` is here because a snapshot is committed with `git add sources`, and
# an ignore file copied out of the upstream repository applies to the snapshot
# too: the dissertation's `.gitignore` says `build` and `*.png`, so its
# `build/repo.typ` and every figure existed on the author's disk but never in git.
# The build passed locally and failed in CI with "file not found", which is the
# exact silent omission this pipeline is supposed to make impossible.
ALWAYS_EXCLUDE = [".git", ".gitignore"]

# Package imports that draw pictures. The HTML exporter cannot turn a bare
# `cetz.canvas` (or a fletcher `diagram`) into an SVG and silently emits
# nothing, so those imports are redirected to a generated module that wraps the
# drawing entry point in `html.frame`. Replacing the *import* instead of the
# call sites keeps this independent of whatever name the document binds the
# module to (`cetz.canvas`, `f.c`, `import ...: *`, ...).
SHIM_PACKAGES = {"cetz": "canvas", "fletcher": "diagram"}
SHIM_IMPORT_RE = re.compile(r'#import\s+"@preview/(cetz|fletcher):([^"]+)"')

# `#scale(...)` around a canvas is a paged-only instruction: during HTML export
# it drops the frame instead of scaling it. Markup-level `#scale` (the `#`
# sigil distinguishes it from cetz's own `scale` used inside a canvas body) is
# pointed at a wrapper that puts the frame outside. The trailing content block
# is forwarded untouched, so no bracket matching is involved.
SCALE_SHIM_IMPORT = f'#import "/{SHIM_DIR}/scale.typ": web-scale\n'

# Data URIs the HTML exporter emits for `#image(...)`: an `<img>` at block level,
# an `<image>` when the picture sits inside a serialized canvas/SVG.
DATA_URI_RE = re.compile(
    r'(<(?:img|image)\b[^>]*?[\s:](?:src|href)=")data:image/([a-z0-9.+-]+);base64,([A-Za-z0-9+/=\s]+)"'
)
IMAGE_EXTS = {".png", ".jpg", ".jpeg", ".gif", ".webp", ".svg", ".avif"}
FIGURE_RE = re.compile(r"<figure[^>]*>.*?</figure>", re.S)
FIGCAPTION_RE = re.compile(r"<figcaption[^>]*>(.*?)</figcaption>", re.S)


def die(msg: str) -> "NoReturn":
    print(f"error: {msg}", file=sys.stderr)
    sys.exit(1)


def run(cmd: list[str], what: str, env: dict | None = None) -> subprocess.CompletedProcess:
    proc = subprocess.run(cmd, capture_output=True, text=True, env=env)
    if proc.returncode != 0:
        print(proc.stdout, file=sys.stderr)
        print(proc.stderr, file=sys.stderr)
        die(f"{what} failed (exit {proc.returncode})")
    return proc


def note_warnings(stderr: str) -> list[str]:
    """Warnings worth surfacing; the paged-only ones are expected."""
    expected = (
        "under active development",
        "page set rule was ignored",
        "align was ignored",
        "scale was ignored",
    )
    interesting = []
    for line in stderr.splitlines():
        if not line.startswith("warning: "):
            continue
        if any(fragment in line for fragment in expected):
            continue
        interesting.append(line)
    return interesting


def resolve(path: str) -> Path:
    p = Path(os.path.expanduser(path))
    return p if p.is_absolute() else (ROOT / p)


def git(dir: Path, *args: str) -> str | None:
    try:
        proc = subprocess.run(
            ["git", "-C", str(dir), *args], capture_output=True, text=True
        )
        return proc.stdout.strip() if proc.returncode == 0 else None
    except OSError:
        return None


def digest(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()[:16]


def git_ignored(paths: list[Path]) -> list[str]:
    """The subset of `paths` that git ignores, i.e. that `git add` will skip.

    Those files exist on this machine only: the next clone (and CI) cannot see
    them, so the note would compile here and fail on the deployed build. Returns
    [] when git is unavailable or this is not a checkout.
    """
    rel = sorted(p.relative_to(ROOT).as_posix() for p in paths if p.is_file())
    if not rel:
        return []
    try:
        proc = subprocess.run(
            ["git", "-C", str(ROOT), "check-ignore", "--stdin"],
            input="\n".join(rel) + "\n",
            capture_output=True,
            text=True,
        )
    except OSError:
        return []
    if proc.returncode not in (0, 1):
        return []
    return proc.stdout.split()


def git_untracked() -> list[str]:
    """Files under sources/ that exist but are not in the index."""
    try:
        proc = subprocess.run(
            ["git", "-C", str(ROOT), "ls-files", "--others", "--", str(SNAPSHOT_DIR)],
            capture_output=True,
            text=True,
        )
    except OSError:
        return []
    if proc.returncode != 0:
        return []
    # `-C ROOT` makes these paths repo-relative already.
    return sorted(proc.stdout.split())


# --------------------------------------------------------------------------
# build cache
#
# typst is the slow part, so a note whose build inputs are unchanged is
# restored from the previous run instead of being compiled again. The cache
# lives in .cache/ (never committed) and is keyed on content only.
#
# A note's inputs are exactly its snapshot tree, plus the pipeline settings that
# can change the output (typst version, HTML flags, site base, enabled shims).
# Multi-file documents are covered because the *whole* tree is in the key: a
# chapter that `#include`s a diagram gets a new key when the diagram changes.
# Cross-note references cannot exist by construction — a single-file note is
# compiled from a temp dir that contains only itself, so `#include "other.typ"`
# would not even compile there.
#
# scripts/compile.py itself is in the key, so editing the post-processing (even
# a comment) invalidates every page. That is the conservative direction: a
# stale page can never be explained away by a forgotten version bump.
# --------------------------------------------------------------------------

CACHE_VERSION = 1


def pipeline_revision() -> str:
    return hashlib.sha256(Path(__file__).read_bytes()).hexdigest()[:16]


def cache_key(
    slug: str, entry_name: str, hashes: dict[str, str], options: dict
) -> str:
    material = json.dumps(
        {
            "version": CACHE_VERSION,
            "pipeline": pipeline_revision(),
            "slug": slug,
            "entry": entry_name,
            "options": options,
            "files": dict(sorted(hashes.items())),
        },
        ensure_ascii=False,
        sort_keys=True,
    )
    return hashlib.sha256(material.encode()).hexdigest()[:32]


def cache_read(slug: str, key: str, pdf_name: str) -> dict | None:
    """Restore the artifacts of a matching previous build, or return None."""
    entry = CACHE_DIR / slug
    meta_file = entry / "meta.json"
    if not (
        meta_file.is_file()
        and (entry / "page.html").is_file()
        and (entry / "document.pdf").is_file()
    ):
        return None
    try:
        meta = json.loads(meta_file.read_text())
    except (OSError, json.JSONDecodeError):
        return None
    if meta.get("version") != CACHE_VERSION or meta.get("key") != key:
        return None
    if meta.get("pdfName") != pdf_name:
        return None

    page = NOTES_DIR / f"{slug}.html"
    page.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(entry / "page.html", page)
    shutil.copy2(entry / "document.pdf", PDF_DIR / pdf_name)
    images = IMAGE_DIR / slug
    shutil.rmtree(images, ignore_errors=True)
    if (entry / "images").is_dir():
        shutil.copytree(entry / "images", images)
    return meta


def cache_write(
    slug: str, key: str, meta: dict, page: Path, pdf: Path, images: Path | None
) -> None:
    """Publish a build into the cache atomically (meta.json is written last)."""
    entry = CACHE_DIR / slug
    entry.parent.mkdir(parents=True, exist_ok=True)
    tmp = Path(tempfile.mkdtemp(dir=entry.parent, prefix=f".{entry.name}."))
    try:
        shutil.copy2(page, tmp / "page.html")
        shutil.copy2(pdf, tmp / "document.pdf")
        if images is not None and images.is_dir():
            shutil.copytree(images, tmp / "images")
        # No sort_keys: the toc entries are re-emitted into notes.json verbatim,
        # so their key order has to survive the round trip.
        (tmp / "meta.json").write_text(
            json.dumps(
                {**meta, "version": CACHE_VERSION, "key": key},
                ensure_ascii=False,
                indent=2,
            )
            + "\n"
        )
        shutil.rmtree(entry, ignore_errors=True)
        tmp.rename(entry)
    except BaseException:
        shutil.rmtree(tmp, ignore_errors=True)
        raise


def cache_prune(keep: set[str]) -> None:
    """Drop entries for notes that are no longer in blog.toml."""
    if not CACHE_DIR.is_dir():
        return
    stale = [
        meta.parent
        for meta in CACHE_DIR.rglob("meta.json")
        if meta.parent.relative_to(CACHE_DIR).as_posix() not in keep
    ]
    for entry in stale:
        shutil.rmtree(entry, ignore_errors=True)
    # ... and the group directories left empty behind them.
    for group in sorted(CACHE_DIR.iterdir()):
        if group.is_dir() and not any(group.iterdir()):
            group.rmdir()


# --------------------------------------------------------------------------
# directory snapshots
# --------------------------------------------------------------------------


def excluded(rel: str, patterns: list[str]) -> bool:
    return any(fnmatch.fnmatch(rel, pat) or rel == pat for pat in patterns)


def walk_tree(root: Path, patterns: list[str]) -> dict[str, Path]:
    """Every regular file under `root`, keyed by POSIX relative path."""
    found: dict[str, Path] = {}
    if not root.is_dir():
        return found
    for dirpath, dirnames, filenames in os.walk(root):
        here = Path(dirpath)
        rel_dir = here.relative_to(root).as_posix()
        keep = []
        for name in sorted(dirnames):
            rel = name if rel_dir == "." else f"{rel_dir}/{name}"
            if name in ALWAYS_EXCLUDE or excluded(rel, patterns):
                continue
            keep.append(name)
        dirnames[:] = keep
        for name in sorted(filenames):
            rel = name if rel_dir == "." else f"{rel_dir}/{name}"
            if excluded(rel, patterns):
                continue
            found[rel] = here / name
    return found


def tree_hashes(root: Path, patterns: list[str]) -> dict[str, str]:
    return {rel: digest(p.read_bytes()) for rel, p in walk_tree(root, patterns).items()}


def refresh_tree(live: Path, snap: Path, patterns: list[str]) -> dict[str, str]:
    """Mirror `live` into `snap` (only rewriting what changed). Returns hashes."""
    wanted = walk_tree(live, patterns)
    if snap.is_dir():
        for rel in walk_tree(snap, []):
            if rel not in wanted:
                (snap / rel).unlink()
    hashes: dict[str, str] = {}
    for rel, src in wanted.items():
        data = src.read_bytes()
        dst = snap / rel
        if not dst.is_file() or dst.read_bytes() != data:
            dst.parent.mkdir(parents=True, exist_ok=True)
            dst.write_bytes(data)
        hashes[rel] = digest(data)
    return hashes


def tree_diff(live: Path, snap: Path, patterns: list[str]) -> list[str]:
    """Relative paths that differ (either direction) between live and snapshot."""
    live_hashes = tree_hashes(live, patterns) if live.is_dir() else {}
    snap_hashes = tree_hashes(snap, []) if snap.is_dir() else {}
    return sorted(
        rel
        for rel in live_hashes.keys() | snap_hashes.keys()
        if live_hashes.get(rel) != snap_hashes.get(rel)
    )


# --------------------------------------------------------------------------
# typst binary, pinned
# --------------------------------------------------------------------------

ASSET_TRIPLES = {
    ("linux", "x86_64"): "x86_64-unknown-linux-musl",
    ("linux", "aarch64"): "aarch64-unknown-linux-musl",
    ("darwin", "x86_64"): "x86_64-apple-darwin",
    ("darwin", "arm64"): "aarch64-apple-darwin",
}


def ensure_typst(version: str) -> tuple[Path, str]:
    binary = TOOLS / "typst"
    stamp = TOOLS / "typst.version"
    if binary.exists() and stamp.exists() and stamp.read_text().strip() == version:
        return binary, version

    key = (platform.system().lower(), platform.machine())
    if key not in ASSET_TRIPLES:
        die(f"no prebuilt typst for {key}; install typst {version} manually")
    triple = ASSET_TRIPLES[key]
    url = (
        f"https://github.com/typst/typst/releases/download/"
        f"v{version}/typst-{triple}.tar.xz"
    )

    TOOLS.mkdir(parents=True, exist_ok=True)
    print(f"  fetching typst {version} ({triple})")
    with tempfile.TemporaryDirectory() as tmp:
        archive = Path(tmp) / "typst.tar.xz"
        try:
            with urllib.request.urlopen(url, timeout=120) as resp:
                archive.write_bytes(resp.read())
        except Exception as exc:  # noqa: BLE001 - network is user-visible
            die(f"could not download typst: {exc}")
        with tarfile.open(archive) as tar:
            member = next(m for m in tar.getmembers() if m.name.endswith("/typst"))
            member.name = "typst"
            tar.extract(member, tmp, filter="data")
        shutil.copy2(Path(tmp) / "typst", binary)
    binary.chmod(0o755)
    stamp.write_text(version + "\n")

    found = run([str(binary), "--version"], "typst --version").stdout.split()[1]
    if version not in found:
        die(f"wrong typst binary: {found}")
    return binary, found


# --------------------------------------------------------------------------
# the diagram shim (build tree only)
# --------------------------------------------------------------------------


def shim_path(package: str, version: str) -> str:
    """Shim path relative to the shim dir.

    The file stem has to be the package name: typst derives the implicit module
    binding from it, so `#import "@preview/cetz:0.4.2"` only keeps working if
    the replacement still binds `cetz`. The version lives in a directory so two
    documents importing different cetz versions cannot collide.
    """
    return f"{version.replace('.', '-')}/{package}.typ"


def shim_module(package: str, version: str) -> str:
    """A module that re-exports `package`, drawing entry point wrapped."""
    function = SHIM_PACKAGES[package]
    return f"""// generated by scripts/compile.py — do not edit
#import "@preview/{package}:{version}": *
#let _unwrapped_{function} = {function}
#let {function}(..args) = html.frame(_unwrapped_{function}(..args))
"""


def apply_shim(build: Path) -> int:
    """Redirect drawing imports in `build` to html.frame wrappers.

    Returns the number of rewritten imports. Everything here is textual on
    purpose: the three rules are anchored on import statements (a package path
    in quotes) and on the markup-level `#scale` sigil, so no parser or bracket
    matching is needed, and aliasing cannot break the wrapper.
    """
    shim_dir = build / SHIM_DIR
    shim_dir.mkdir()
    modules: dict[tuple[str, str], str] = {}
    rewrites = 0
    scaled = False

    for path in sorted(build.rglob("*.typ")):
        if shim_dir in path.parents:
            continue
        source = path.read_text()

        def redirect(match: re.Match) -> str:
            nonlocal rewrites
            package, version = match.group(1), match.group(2)
            modules[(package, version)] = shim_module(package, version)
            rewrites += 1
            return f'#import "/{SHIM_DIR}/{shim_path(package, version)}"'

        shimmed = SHIM_IMPORT_RE.sub(redirect, source)

        if "#scale(" in shimmed:
            shimmed, count = re.subn(r"#scale\(", "#web-scale(", shimmed)
            if count:
                scaled = True
                shimmed = SCALE_SHIM_IMPORT + shimmed

        if shimmed != source:
            path.write_text(shimmed)

    for (package, version), text in modules.items():
        target = shim_dir / shim_path(package, version)
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(text)
    if scaled:
        (shim_dir / "scale.typ").write_text(
            "// generated by scripts/compile.py — do not edit\n"
            "#let web-scale(..args) = html.frame(scale(..args))\n"
        )
    return rewrites


# --------------------------------------------------------------------------
# HTML post-processing
# --------------------------------------------------------------------------

BODY_RE = re.compile(r"<body[^>]*>(.*)</body>", re.S)
HEADING_RE = re.compile(r"<h([1-6])([^>]*)>(.*?)</h\1>", re.S)
TAG_RE = re.compile(r"<[^>]+>")
NUMBERING_RE = re.compile(r"^(\d+(?:\.\d+)*)\s*(.*)$", re.S)


def visible(html: str) -> str:
    text = TAG_RE.sub("", html)
    return re.sub(r"\s+", " ", text).strip()


def slugify(text: str) -> str:
    text = text.lower()
    text = re.sub(r"[^\w\u3400-\u9fff]+", "-", text)
    return re.sub(r"-{2,}", "-", text).strip("-")[:48]


def extract_body(full_html: str) -> tuple[str, list[dict]]:
    """Pull out <body>, give every heading a stable id, and build a TOC."""
    match = BODY_RE.search(full_html)
    if not match:
        die("typst produced no <body> (HTML export broken?)")
    body = match.group(1)

    used = set(re.findall(r'id="([^"]+)"', body))
    toc: list[dict] = []
    counter = {"n": 0}

    def repl(m: re.Match) -> str:
        level, attrs, inner = m.group(1), m.group(2), m.group(3)
        text = visible(inner)
        if 'id="' not in attrs:
            num = NUMBERING_RE.match(text)
            if num:
                # "2.1.5 关系索引" -> "sec-2-1-5": short, stable, ASCII.
                anchor = "sec-" + num.group(1).replace(".", "-")
            else:
                anchor = slugify(text) or "section"
                counter["n"] += 1
                if anchor in used:
                    anchor = f"{anchor}-{counter['n']}"
            used.add(anchor)
            attrs = f' id="{anchor}"' + attrs
        else:
            anchor = re.search(r'id="([^"]+)"', attrs).group(1)
        toc.append({"level": int(level), "text": text, "id": anchor})
        return f"<h{level}{attrs}>{inner}</h{level}>"

    body = HEADING_RE.sub(repl, body)

    # Wide tables need their own scroll container on narrow screens.
    body = re.sub(
        r"<table>(.*?)</table>",
        r'<div class="table-wrap"><table>\1</table></div>',
        body,
        flags=re.S,
    )

    # Display equations get a scroll container too. The wrapper is required
    # because `overflow` needs a block-level box, and setting it on <math>
    # itself would mean overriding its `display`, which destroys MathML layout.
    body = re.sub(
        r'<math display="block">(.*?)</math>',
        r'<div class="math-block"><math display="block">\1</math></div>',
        body,
        flags=re.S,
    )
    return body.strip(), toc


def check_figures(slug: str, body: str, shimmed: bool) -> int:
    """Every <figure> must carry graphics, or the exporter dropped them."""
    figures = FIGURE_RE.findall(body)
    for figure in figures:
        if "<svg" in figure or "<img" in figure:
            continue
        caption = FIGCAPTION_RE.search(figure)
        label = visible(caption.group(1)) if caption else visible(figure)[:80]
        hint = (
            'the diagram shim is on, so this is a new drawing construct it does '
            'not cover: add it to scripts/compile.py'
            if shimmed
            else 'set shim = ["diagram"] in blog.toml to wrap cetz/fletcher drawings'
        )
        die(f"[{slug}] figure has no graphics ({label!r}); {hint}")
    return len(figures)


def extract_images(
    slug: str, body: str, tree: dict[str, Path], base: str
) -> tuple[str, int]:
    """Move base64 figures out of the page into public/images/<slug>/.

    The exporter inlines `#image(...)` as a data URI, which makes a page with a
    dozen plots weigh megabytes and gives the browser nothing to cache. Names
    are recovered by matching the payload against the files in the snapshot, so
    a plot stays `miss-mine-to-perf-log.png` instead of becoming a hash.
    """
    by_payload: dict[str, str] = {}
    for rel, path in tree.items():
        if path.suffix.lower() not in IMAGE_EXTS:
            continue
        try:
            by_payload[base64.b64encode(path.read_bytes()).decode()] = Path(rel).name
        except OSError:
            continue

    prefix = "" if base in ("", "/") else "/" + base.strip("/")
    out_dir = IMAGE_DIR / slug
    written: dict[str, bytes] = {}
    used_names: set[str] = set()

    def replace(match: re.Match) -> str:
        attribute, subtype, payload = match.group(1), match.group(2), match.group(3)
        payload = re.sub(r"\s+", "", payload)
        try:
            data = base64.b64decode(payload)
        except Exception:  # noqa: BLE001 - malformed base64 is a typst bug
            die(f"[{slug}] could not decode an inlined image")
        name = by_payload.get(payload)
        if name is None:
            ext = mimetypes.guess_extension(f"image/{subtype}") or ".bin"
            name = f"figure-{digest(data)}{ext}"
        stem, suffix = os.path.splitext(name)
        candidate, index = name, 1
        while candidate in used_names and written.get(candidate) != data:
            candidate = f"{stem}-{index}{suffix}"
            index += 1
        used_names.add(candidate)
        written[candidate] = data
        loading = ' loading="lazy" decoding="async"' if attribute.startswith("<img") else ""
        return f'{attribute}{prefix}/images/{slug}/{candidate}"{loading}'

    body = DATA_URI_RE.sub(replace, body)
    remaining = body.count("data:image/")
    if remaining:
        # The exporter changed its spelling of data URIs; still correct, but the
        # page is now multi-megabyte, so it is worth a nudge.
        print(f"    warning: {remaining} inlined image(s) left in the page", file=sys.stderr)

    shutil.rmtree(out_dir, ignore_errors=True)
    if written:
        out_dir.mkdir(parents=True, exist_ok=True)
        for name, data in written.items():
            (out_dir / name).write_bytes(data)
    return body, len(written)


# --------------------------------------------------------------------------
# main
# --------------------------------------------------------------------------


def is_tree(note: dict) -> bool:
    return "entry" in note


def load_manifest() -> tuple[dict, dict, list[dict]]:
    if not MANIFEST.exists():
        die(f"missing {MANIFEST}")
    manifest = tomllib.loads(MANIFEST.read_text())
    projects = {p["id"]: p for p in manifest.get("project", [])}
    notes = manifest.get("note", [])
    if not notes:
        die("blog.toml has no [[note]] entries")
    for note in notes:
        slug = note["slug"].strip("/")
        if note["project"] not in projects:
            die(f"[{slug}] unknown project id: {note['project']}")
        if is_tree(note):
            if note["source"].endswith(".typ"):
                die(f"[{slug}] entry is set but source is a file: {note['source']}")
            if not note["entry"].endswith(".typ"):
                die(f"[{slug}] entry must be a .typ file: {note['entry']}")
            unknown = set(note.get("shim", [])) - {"diagram"}
            if unknown:
                die(f"[{slug}] unknown shim(s): {sorted(unknown)}")
        elif resolve(note["source"]).suffix != ".typ":
            die(
                f"[{slug}] source is not a .typ file: {note['source']} "
                '(for a directory of files, also set entry = "web.typ")'
            )
    return manifest["site"], projects, notes


def snapshot_path(slug: str) -> Path:
    return SNAPSHOT_DIR / f"{slug}.typ"


def snapshot_tree(slug: str) -> Path:
    return SNAPSHOT_DIR / slug


def check(notes: list[dict]) -> None:
    """Fail if a committed snapshot no longer matches its live source."""
    stale, missing_live, gone = [], [], []
    for note in notes:
        slug = note["slug"].strip("/")
        live = resolve(note["source"])

        if is_tree(note):
            snap = snapshot_tree(slug)
            if not live.is_dir():
                missing_live.append(slug)
                if not snap.is_dir():
                    die(f"[{slug}] no live source and no committed snapshot")
                continue
            if not snap.is_dir():
                gone.append(slug)
                continue
            changed = tree_diff(live, snap, ALWAYS_EXCLUDE + note.get("exclude", []))
            if changed:
                stale.append(f"{slug} ({len(changed)} file(s), e.g. {changed[0]})")
            continue

        snap = snapshot_path(slug)
        if not live.is_file():
            missing_live.append(slug)
            if not snap.is_file():
                die(f"[{slug}] no live source and no committed snapshot")
            continue
        if not snap.is_file() or snap.read_bytes() != live.read_bytes():
            stale.append(slug)

    for slug in missing_live:
        print(f"  note: {slug} — live source absent, using committed snapshot")

    # A snapshot that is not entirely in git is not a snapshot: a fresh clone
    # and CI would build something else (this is how build/repo.typ once went
    # missing while every local build kept working).
    untracked = git_untracked()
    if untracked:
        shown = ", ".join(untracked[:3]) + (" ..." if len(untracked) > 3 else "")
        die(
            f"{len(untracked)} snapshot file(s) are not committed: {shown}\n"
            "  a snapshot is the build input, so CI only sees what is in git.\n"
            "  fix: git add sources  (or `git add -f` if git ignores the path)"
        )

    if stale or gone:
        for slug in gone:
            print(f"  no snapshot: {slug}", file=sys.stderr)
        for slug in stale:
            print(f"  stale: {slug}", file=sys.stderr)
        die("snapshots are stale; run ./compile.sh and commit sources/")
    print(f"snapshots up to date ({len(notes)} note(s))")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--check",
        action="store_true",
        help="only verify that sources/ matches the live documents (no typst needed)",
    )
    parser.add_argument(
        "--no-cache",
        action="store_true",
        help="ignore cached artifacts and recompile every note (still fills the cache)",
    )
    args = parser.parse_args()

    site, projects, notes = load_manifest()

    if args.check:
        check(notes)
        return

    typst_pin = tomllib.loads(MANIFEST.read_text())["typst"]["version"]
    print(f"notes pipeline: {len(notes)} note(s), typst {typst_pin}")
    typst, tver = ensure_typst(typst_pin)
    major, minor = (int(x) for x in tver.split(".")[:2])
    if (major, minor) < (0, 15):
        die(f"typst {tver} cannot export math to HTML; need >= 0.15")

    shutil.rmtree(NOTES_DIR, ignore_errors=True)
    NOTES_DIR.mkdir(parents=True, exist_ok=True)
    PDF_DIR.mkdir(parents=True, exist_ok=True)
    SNAPSHOT_DIR.mkdir(parents=True, exist_ok=True)

    out_notes: list[dict] = []
    # Provenance is a property of the snapshot, so it is committed next to it:
    # a machine without the project checkout must still label each page with the
    # commit it came from.
    saved_provenance: dict[str, dict] = (
        json.loads(PROVENANCE.read_text()) if PROVENANCE.is_file() else {}
    )
    provenance: dict[str, dict] = dict(saved_provenance)
    warnings: list[str] = []
    base = site.get("base", "/")
    n_cached = 0

    for note in notes:
        slug = note["slug"].strip("/")
        declared = note["source"]
        live = resolve(declared)
        entry_name = note.get("entry", "")
        shims = note.get("shim", [])
        print(f"  {slug}")

        # 1. refresh the snapshot from the live document when we have it
        if is_tree(note):
            snap = snapshot_tree(slug)
            excludes = ALWAYS_EXCLUDE + note.get("exclude", [])
            if live.is_dir():
                hashes = refresh_tree(live, snap, excludes)
                if entry_name not in hashes:
                    die(f"[{slug}] entry {entry_name!r} not found under {declared}")
                print(f"    snapshot updated from {declared} ({len(hashes)} file(s))")
                provenance[slug] = {
                    "declared": declared,
                    "entry": entry_name,
                    "commit": git(live, "rev-parse", "--short", "HEAD"),
                    "dirty": bool(git(live, "status", "--porcelain")),
                    "files": hashes,
                }
            elif snap.is_dir():
                print("    live source absent, using committed snapshot")
                provenance[slug] = saved_provenance.get(
                    slug,
                    {"declared": declared, "entry": entry_name, "commit": None, "dirty": False},
                )
            else:
                die(f"[{slug}] neither the live document nor a snapshot exists: {live}")
            if not (snap / entry_name).is_file():
                die(f"[{slug}] snapshot has no {entry_name}")
            tree = walk_tree(snap, [])
        else:
            snap = snapshot_path(slug)
            if live.is_file():
                content = live.read_bytes()
                if not snap.is_file() or snap.read_bytes() != content:
                    snap.parent.mkdir(parents=True, exist_ok=True)
                    snap.write_bytes(content)
                    print(f"    snapshot updated from {declared}")
                provenance[slug] = {
                    "declared": declared,
                    "commit": git(live.parent, "rev-parse", "--short", "HEAD"),
                    "dirty": bool(git(live.parent, "status", "--porcelain", "--", live.name)),
                }
            elif snap.is_file():
                print("    live source absent, using committed snapshot")
                provenance[slug] = saved_provenance.get(
                    slug, {"declared": declared, "commit": None, "dirty": False}
                )
            else:
                die(f"[{slug}] neither the live document nor a snapshot exists: {live}")
            entry_name = snap.name
            tree = {entry_name: snap}

        # A file git ignores never reaches the repository, so this note would
        # build on this machine only and fail in CI ("file not found"). The
        # `.gitignore` that caused this is no longer snapshotted, but an ignore
        # pattern from the root .gitignore or a future one would still bite.
        ignored = git_ignored(list(tree.values()))
        if ignored:
            shown = ", ".join(ignored[:3]) + (" ..." if len(ignored) > 3 else "")
            die(
                f"[{slug}] {len(ignored)} snapshot file(s) are git-ignored: {shown}\n"
                "  they exist here but would never be committed, so CI cannot see them.\n"
                "  fix: git add -f them, or drop them via `exclude` in blog.toml"
            )

        # 2. cache: content-addressed. Same snapshot tree + same pipeline
        #    settings => the previous artifacts are still correct.
        pdf_name = slug.replace("/", "-") + ".pdf"
        pdf_path = PDF_DIR / pdf_name
        hashes = {rel: digest(p.read_bytes()) for rel, p in tree.items()}
        key = cache_key(
            slug,
            entry_name,
            hashes,
            {
                "typst": tver,
                "html_flags": HTML_FLAGS,
                "base": base,
                "shims": sorted(shims),
            },
        )
        cached = None if args.no_cache else cache_read(slug, key, pdf_name)

        if cached:
            n_math = cached["math"]
            n_figures = cached["figures"]
            n_images = cached["images"]
            toc = cached["toc"]
            html_bytes = cached["htmlBytes"]
            pdf_bytes = cached["pdfBytes"]
            n_cached += 1
        else:
            # 3. build the HTML from a throwaway copy of the snapshot, so that
            #    the diagram shim never touches what is committed
            with tempfile.TemporaryDirectory() as tmp:
                build = Path(tmp) / "build"
                if is_tree(note):
                    shutil.copytree(
                        snap, build, ignore=shutil.ignore_patterns(*ALWAYS_EXCLUDE)
                    )
                else:
                    build.mkdir()
                    shutil.copy2(snap, build / entry_name)

                rewrites = 0
                if "diagram" in shims:
                    rewrites = apply_shim(build)
                page = Path(tmp) / "page.html"
                proc = run(
                    [
                        str(typst),
                        "compile",
                        *HTML_FLAGS,
                        "--root",
                        str(build),
                        str(build / entry_name),
                        str(page),
                    ],
                    f"typst html for {slug}",
                    REPRO_ENV,
                )
                warnings.extend(f"[{slug}] {w}" for w in note_warnings(proc.stderr))
                full = page.read_text()
                body, toc = extract_body(full)

                if "diagram" in shims:
                    print(f"    shim    {rewrites} import(s) redirected")

                has_math_src = any(
                    "$" in p.read_text(errors="replace")
                    for p in tree.values()
                    if p.suffix == ".typ" and p.is_file()
                )
                n_math = body.count("<math")
                if has_math_src and n_math == 0:
                    die(
                        f"[{slug}] source has math but the page has no <math>; "
                        "typst dropped the equations (needs >= 0.15)"
                    )

            n_figures = check_figures(slug, body, "diagram" in shims)
            body, n_images = extract_images(slug, body, tree, base)
            page_path = NOTES_DIR / f"{slug}.html"
            page_path.parent.mkdir(parents=True, exist_ok=True)
            page_path.write_text(body)

            # 4. PDF, from the pristine snapshot (the shim is HTML-only)
            run(
                [
                    str(typst),
                    "compile",
                    "--root",
                    str(snap if is_tree(note) else snap.parent),
                    str(snap / entry_name if is_tree(note) else snap),
                    str(pdf_path),
                ],
                f"typst pdf for {slug}",
                REPRO_ENV,
            )

            html_bytes = len(body)
            pdf_bytes = pdf_path.stat().st_size
            cache_write(
                slug,
                key,
                {
                    "pdfName": pdf_name,
                    "math": n_math,
                    "figures": n_figures,
                    "images": n_images,
                    "toc": toc,
                    "htmlBytes": html_bytes,
                    "pdfBytes": pdf_bytes,
                },
                page_path,
                pdf_path,
                IMAGE_DIR / slug,
            )

        out_notes.append(
            {
                "slug": slug,
                "title": note["title"],
                "summary": note.get("summary", ""),
                "tags": note.get("tags", []),
                "date": note.get("date"),
                "order": note.get("order", 999),
                "project": note["project"],
                "kind": "typst",
                "pdf": f"pdf/{pdf_name}",
                "source": provenance.get(
                    slug, {"declared": declared, "commit": None, "dirty": False}
                ),
                "snapshot": (
                    f"sources/{slug}/{entry_name}"
                    if is_tree(note)
                    else f"sources/{slug}.typ"
                ),
                "math": n_math,
                "figures": n_figures,
                "images": n_images,
                "toc": toc,
            }
        )
        if cached:
            print(
                f"    cached  {html_bytes // 1024} KB html, {pdf_bytes // 1024} KB pdf, "
                f"{n_math} equations, {n_figures} figures, {len(toc)} headings"
            )
        else:
            print(
                f"    html    {html_bytes // 1024} KB, {n_math} equations, "
                f"{n_figures} figures, {len(toc)} headings"
            )
            print(f"    pdf     {pdf_bytes // 1024} KB")

    if provenance:
        PROVENANCE.write_text(
            json.dumps(provenance, ensure_ascii=False, indent=2, sort_keys=True) + "\n"
        )

    cache_prune({note["slug"].strip("/") for note in notes})

    out_notes.sort(key=lambda n: (projects[n["project"]].get("order", 999), n["order"]))
    payload = {
        "typstVersion": tver,
        "site": site,
        "projects": sorted(projects.values(), key=lambda p: p.get("order", 999)),
        "notes": out_notes,
    }
    NOTES_JSON.parent.mkdir(parents=True, exist_ok=True)
    NOTES_JSON.write_text(json.dumps(payload, ensure_ascii=False, indent=2) + "\n")

    for w in warnings:
        print(f"warning: {w}", file=sys.stderr)

    print(
        f"done: {len(out_notes)} note(s) "
        f"({len(out_notes) - n_cached} compiled, {n_cached} cached) "
        "-> src/generated/, public/pdf/, public/images/"
    )


if __name__ == "__main__":
    main()
