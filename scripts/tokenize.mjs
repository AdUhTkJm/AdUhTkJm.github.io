#!/usr/bin/env node
/* eslint-disable no-console -- this is a CLI script; its output is the report. */
/**
 * Token counts for the notes.
 *
 * `src/generated/notes.json` points at the entry `.typ` file of each note.
 * For this script, a note's source is that file plus everything it reaches
 * through `#include`, and **not** the files it reaches through `#import`:
 *
 *   - `#include` is content: the included file is part of the document, so it
 *     is part of what an LLM has to read;
 *   - `#import` is code: a helper library (`heb.typ`, `common.typ`, …) is not
 *     the article, and counting it would make every part of a series inherit
 *     the size of the shared helper.
 *
 * The include closure is resolved statically. `#include` inside comments,
 * strings or raw blocks is ignored. A dynamic include (`#include path`) is an
 * error rather than a silent undercount: there is no reliable way to resolve
 * it without running Typst, and the author should use a literal path.
 *
 * The tokenizer is DeepSeek-V4.1-Flash's own `tokenizer.json`, vendored under
 * `scripts/tokenizers/`. It is pinned by revision and checksum, because token
 * counts are only comparable within one tokenizer revision.
 *
 * Output: `src/generated/token-counts.json`, keyed by slug. Not committed.
 */
import { createHash } from "node:crypto";
import {
  existsSync,
  mkdirSync,
  readFileSync,
  renameSync,
  writeFileSync,
} from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { Tokenizer } from "@huggingface/tokenizers";

const ROOT = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");
const NOTES_JSON = path.join(ROOT, "src", "generated", "notes.json");
const OUTPUT = path.join(ROOT, "src", "generated", "token-counts.json");
const SNAPSHOT_ROOT = path.join(ROOT, "sources");
const TOKENIZER_DIR = path.join(
  ROOT,
  "scripts",
  "tokenizers",
  "deepseek-v4.1-flash"
);
const TOKENIZER_JSON = path.join(TOKENIZER_DIR, "tokenizer.json");
const TOKENIZER_CONFIG = path.join(TOKENIZER_DIR, "tokenizer_config.json");

const TOKENIZER = {
  model: "deepseek-ai/DeepSeek-V4.1-Flash",
  revision: "314113f8a7dadb388215396ba5fbee2c610a04d6",
};

function fail(message) {
  console.error(`error: ${message}`);
  process.exit(1);
}

function readText(file) {
  try {
    return readFileSync(file, "utf8");
  } catch (error) {
    fail(`cannot read ${path.relative(ROOT, file)}: ${error.message}`);
  }
}

function lineOf(source, offset) {
  let line = 1;
  for (let i = 0; i < offset; i++) if (source[i] === "\n") line++;
  return line;
}

/** Skip a `//` comment; `i` points just after the two slashes. */
function skipLineComment(source, i) {
  const newline = source.indexOf("\n", i);
  return newline === -1 ? source.length : newline + 1;
}

/** Skip a (possibly nested) `/* ... *\/` comment; `i` points after `/*`. */
function skipBlockComment(source, i) {
  let depth = 1;
  while (i < source.length) {
    if (source.startsWith("/*", i)) {
      depth++;
      i += 2;
    } else if (source.startsWith("*/", i)) {
      depth--;
      i += 2;
      if (depth === 0) return i;
    } else {
      i++;
    }
  }
  return i;
}

/** Read a Typst string literal; `i` points at the opening quote. */
function readString(source, i, file) {
  const start = i;
  i++;
  let value = "";
  while (i < source.length) {
    const char = source[i];
    if (char === "\\") {
      const next = source[i + 1];
      if (next === undefined) break;
      // Include paths only need the escapes that can appear in a path. Keeping
      // the backslash for anything else is closer to Typst than dropping it.
      value += next === '"' || next === "\\" ? next : `\\${next}`;
      i += 2;
    } else if (char === '"') {
      return { value, end: i + 1 };
    } else {
      value += char;
      i++;
    }
  }
  throw new Error(
    `${path.relative(ROOT, file)}:${lineOf(source, start)}: unterminated string`
  );
}

/** Skip a Typst raw block; `i` points at the first backtick. */
function skipRaw(source, i) {
  let ticks = 0;
  while (source[i + ticks] === "`") ticks++;
  const close = source.indexOf("`".repeat(ticks), i + ticks);
  return close === -1 ? source.length : close + ticks;
}

/**
 * Every literal `#include "..."` in a Typst file, in source order.
 *
 * This deliberately does not try to evaluate conditions. A conditional include
 * is still a file the source refers to, and the source text is what we count.
 */
function scanIncludes(source, file) {
  const includes = [];
  let i = 0;

  while (i < source.length) {
    const char = source[i];

    if (char === "/" && source[i + 1] === "/") {
      i = skipLineComment(source, i + 2);
      continue;
    }
    if (char === "/" && source[i + 1] === "*") {
      i = skipBlockComment(source, i + 2);
      continue;
    }
    if (char === "\\") {
      // A markup escape such as \" or \` is not a string/raw opener.
      i += 2;
      continue;
    }
    if (char === '"') {
      i = readString(source, i, file).end;
      continue;
    }
    if (char === "`") {
      i = skipRaw(source, i);
      continue;
    }
    if (char !== "#") {
      i++;
      continue;
    }

    let j = i + 1;
    while (j < source.length && /[A-Za-z0-9_-]/.test(source[j])) j++;
    const word = source.slice(i + 1, j);
    if (word !== "include") {
      i = j;
      continue;
    }

    let k = j;
    while (k < source.length && /\s/.test(source[k])) k++;
    if (source[k] === "(") {
      k++;
      while (k < source.length && /\s/.test(source[k])) k++;
    }
    if (source[k] !== '"') {
      throw new Error(
        `${path.relative(ROOT, file)}:${lineOf(source, i)}: ` +
          "non-literal #include is not supported; use a literal path"
      );
    }

    const { value, end } = readString(source, k, file);
    includes.push({ path: value, line: lineOf(source, i) });
    i = end;
  }

  return includes;
}

/** Resolve one include target. Package includes are external and skipped. */
function resolveInclude(from, spec, line) {
  if (spec.startsWith("@")) return null;

  let target = path.resolve(path.dirname(from), spec);
  if (!existsSync(target) && path.extname(target) === "") {
    target += ".typ";
  }
  if (!existsSync(target)) {
    throw new Error(
      `${path.relative(ROOT, from)}:${line}: included file not found: ${spec}`
    );
  }
  if (!target.startsWith(SNAPSHOT_ROOT + path.sep)) {
    throw new Error(
      `${path.relative(ROOT, from)}:${line}: include escapes sources/: ${spec}`
    );
  }
  if (!target.toLowerCase().endsWith(".typ")) {
    throw new Error(
      `${path.relative(ROOT, from)}:${line}: include is not a .typ file: ${spec}`
    );
  }
  return target;
}

/**
 * Entry file plus its recursive `#include` closure, in source order.
 * A file included twice is counted once: the source tree contains it once, and
 * an LLM reading the files would read it once.
 */
function sourceFiles(entry) {
  const files = [];
  const seen = new Set();

  function visit(file) {
    if (seen.has(file)) return;
    seen.add(file);
    files.push(file);

    for (const include of scanIncludes(readText(file), file)) {
      const target = resolveInclude(file, include.path, include.line);
      if (target) visit(target);
    }
  }

  visit(entry);
  return files;
}

function relative(file) {
  return path.relative(ROOT, file).split(path.sep).join("/");
}

function main() {
  if (!existsSync(NOTES_JSON)) {
    fail("src/generated/notes.json is missing; run `python3 scripts/compile.py`");
  }
  if (!existsSync(TOKENIZER_JSON) || !existsSync(TOKENIZER_CONFIG)) {
    fail(`tokenizer files are missing from ${path.relative(ROOT, TOKENIZER_DIR)}`);
  }

  const manifest = JSON.parse(readText(NOTES_JSON));
  const tokenizer = new Tokenizer(
    JSON.parse(readText(TOKENIZER_JSON)),
    JSON.parse(readText(TOKENIZER_CONFIG))
  );
  const tokenizerSha256 = createHash("sha256")
    .update(readFileSync(TOKENIZER_JSON))
    .digest("hex");

  const notes = {};
  let total = 0;

  for (const note of manifest.notes) {
    const entry = path.resolve(ROOT, note.snapshot);
    let files;
    try {
      files = sourceFiles(entry);
    } catch (error) {
      fail(`[${note.slug}] ${error.message}`);
    }

    // The separator keeps adjacent files from accidentally forming one token.
    // Source text itself (comments, markup, code, math) is kept verbatim: that
    // is the point of counting the Typst source rather than the rendered page.
    const source = files.map(file => readText(file)).join("\n\n");
    const tokens = tokenizer.encode(source, {
      add_special_tokens: false,
    }).ids.length;

    notes[note.slug] = {
      tokens,
      files: files.map(relative),
    };
    total += tokens;
    console.log(
      `  ${note.slug}: ${tokens.toLocaleString("en-US")} tokens ` +
        `(${files.length} file${files.length === 1 ? "" : "s"})`
    );
  }

  const output = {
    tokenizer: {
      ...TOKENIZER,
      tokenizerSha256,
    },
    notes,
  };

  mkdirSync(path.dirname(OUTPUT), { recursive: true });
  const temporary = `${OUTPUT}.tmp`;
  writeFileSync(temporary, `${JSON.stringify(output, null, 2)}\n`);
  renameSync(temporary, OUTPUT);
  console.log(
    `\n${manifest.notes.length} note(s), ${total.toLocaleString("en-US")} tokens total`
  );
}

main();
