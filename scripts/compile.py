#!/usr/bin/env python3
"""Compile the curated notes in blog.toml into web pages.

The only committed inputs are `blog.toml` and `sources/<slug>.typ` — a snapshot
of each published document. Both the site build and CI compile **from the
snapshot**, never from the live project checkout, so:

  - a fresh clone builds identically without the project repositories;
  - nothing generated is committed (no HTML, no PDFs in git);
  - the build input is exactly the file you can read in `sources/`.

For every [[note]] entry:

    sources/<slug>.typ   ->  src/generated/notes/<slug>.html   semantic HTML + MathML
                         ->  public/pdf/<slug>.pdf             paged A4, for printing

`--check` verifies that the committed snapshots still match the live sources, so
a stale snapshot cannot be pushed.
"""

from __future__ import annotations

import argparse
import json
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
NOTES_DIR = ROOT / "src" / "generated" / "notes"
NOTES_JSON = ROOT / "src" / "generated" / "notes.json"
PDF_DIR = ROOT / "public" / "pdf"
SNAPSHOT_DIR = ROOT / "sources"
PROVENANCE = SNAPSHOT_DIR / "provenance.json"

# typst CLI flags that turn on the experimental HTML exporter.
HTML_FLAGS = ["--features", "html"]

# Reproducible output: without this, every PDF embeds a creation date.
REPRO_ENV = {**os.environ, "SOURCE_DATE_EPOCH": "0"}

# `#import "x.typ"` / `#include "data.json"` would not be in sources/, so the
# snapshot would not build on a machine without the project checkout.
LOCAL_DEP_RE = re.compile(r'^\s*#(?:import|include)\s+"([^"@]+)"', re.M)


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
    """Warnings worth surfacing; the two paged-only ones are expected."""
    interesting = []
    for line in stderr.splitlines():
        if not line.startswith("warning: "):
            continue
        if "under active development" in line:
            continue
        if "page set rule was ignored" in line:
            continue
        if "align was ignored" in line:
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


def read_source(live: Path, declared: str) -> dict:
    """Provenance for a snapshot. Only meaningful where the live file exists."""
    commit = git(live.parent, "rev-parse", "--short", "HEAD")
    dirty = git(live.parent, "status", "--porcelain", "--", live.name)
    return {"declared": declared, "commit": commit, "dirty": bool(dirty)}


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


# --------------------------------------------------------------------------
# main
# --------------------------------------------------------------------------


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
        if resolve(note["source"]).suffix != ".typ":
            die(f"[{slug}] only .typ sources are supported for now")
    return manifest["site"], projects, notes


def snapshot_path(slug: str) -> Path:
    return SNAPSHOT_DIR / f"{slug}.typ"


def check(notes: list[dict]) -> None:
    """Fail if a committed snapshot no longer matches its live source."""
    stale, missing_live = [], []
    for note in notes:
        slug = note["slug"].strip("/")
        live = resolve(note["source"])
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
    if stale:
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

    for note in notes:
        slug = note["slug"].strip("/")
        declared = note["source"]
        live = resolve(declared)
        snap = snapshot_path(slug)
        print(f"  {slug}")

        # 1. refresh the snapshot from the live document when we have it
        if live.is_file():
            content = live.read_bytes()
            if not snap.is_file() or snap.read_bytes() != content:
                snap.parent.mkdir(parents=True, exist_ok=True)
                snap.write_bytes(content)
                print(f"    snapshot updated from {declared}")
            provenance[slug] = read_source(live, declared)
        elif snap.is_file():
            print(f"    live source absent, using committed snapshot")
            provenance[slug] = saved_provenance.get(
                slug, {"declared": declared, "commit": None, "dirty": False}
            )
        else:
            die(f"[{slug}] neither the live document nor a snapshot exists: {live}")

        # A snapshot is only reproducible if the document is self-contained.
        local_deps = LOCAL_DEP_RE.findall(snap.read_text(errors="replace"))
        if local_deps:
            die(
                f"[{slug}] imports local files {local_deps}, which are not in "
                "sources/; inline them or extend the pipeline to snapshot them"
            )

        # 2. build from the snapshot, never from the live file
        root = snap.parent
        with tempfile.TemporaryDirectory() as tmp:
            page = Path(tmp) / "page.html"
            proc = run(
                [str(typst), "compile", *HTML_FLAGS, "--root", str(root), str(snap), str(page)],
                f"typst html for {slug}",
                REPRO_ENV,
            )
            warnings.extend(f"[{slug}] {w}" for w in note_warnings(proc.stderr))
            full = page.read_text()

        body, toc = extract_body(full)

        has_math_src = "$" in snap.read_text(errors="replace")
        n_math = body.count("<math")
        if has_math_src and n_math == 0:
            die(
                f"[{slug}] source has math but the page has no <math>; "
                "typst dropped the equations (needs >= 0.15)"
            )

        page_path = NOTES_DIR / f"{slug}.html"
        page_path.parent.mkdir(parents=True, exist_ok=True)
        page_path.write_text(body)

        # 3. PDF, from the same snapshot
        pdf_name = slug.replace("/", "-") + ".pdf"
        pdf_path = PDF_DIR / pdf_name
        run(
            [str(typst), "compile", "--root", str(root), str(snap), str(pdf_path)],
            f"typst pdf for {slug}",
            REPRO_ENV,
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
                "snapshot": f"sources/{slug}.typ",
                "math": n_math,
                "toc": toc,
            }
        )
        print(f"    html    {len(body) // 1024} KB, {n_math} equations, {len(toc)} headings")
        print(f"    pdf     {pdf_path.stat().st_size // 1024} KB")

    if provenance:
        PROVENANCE.write_text(
            json.dumps(provenance, ensure_ascii=False, indent=2, sort_keys=True) + "\n"
        )

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

    print(f"done: {len(out_notes)} note(s) -> src/generated/, public/pdf/")


if __name__ == "__main__":
    main()
