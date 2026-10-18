# blogs

A notes-first static blog. The pages under `/notes/` are compiled from Typst
documents that live in the project repositories — they are never rewritten here.

```sh
./compile.sh      # refresh sources/, compile notes, build the site
pnpm preview      # serve dist/
```

Only the sources are versioned: `blog.toml` (the allowlist) and
`sources/<slug>.typ` (a snapshot per note, plus `provenance.json`). Compiled
HTML and PDFs are built from those snapshots on every build, locally and in CI —
so a clone builds without any of the project repositories.

- **Publishing a document**: add a `[[note]]` block to `blog.toml`, run
  `./compile.sh`, commit `blog.toml` and `sources/`.
- **How it works, and its caveats**: [PIPELINE.md](./PIPELINE.md).

Built with [Astro](https://astro.build/) and the
[AstroPaper](https://github.com/satnaing/astro-paper) theme; Typst's HTML
exporter supplies the note bodies (MathML for equations), and the same snapshots
are also compiled to A4 PDFs under `/pdf/`.
