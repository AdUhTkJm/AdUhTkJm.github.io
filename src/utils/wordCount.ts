/**
 * Word count for prose written in Chinese (with the occasional English term).
 *
 * Counting rules — the ones Chinese editors actually use:
 *   - every CJK character counts as one 字;
 *   - a run of Latin letters or digits counts as one word;
 *   - whitespace, punctuation and markup count as nothing.
 *
 * Two things are deliberately skipped before counting:
 *   - `<pre>` blocks (code listings are not prose);
 *   - `<math>` blocks (raw MathML would otherwise count every symbol in an
 *     equation, and count `𝑐`/`𝑟` again on every line they appear).
 */
const CJK =
  /[\u2e80-\u2fff\u3005\u3007\u3021-\u3029\u3040-\u30ff\u3400-\u4dbf\u4e00-\u9fff\uf900-\ufaff\uac00-\ud7af]/;

const LATIN_WORD = /[A-Za-z0-9]+/g;

/** Elements whose text content must never be counted. */
const SKIPPED_BLOCKS = /<(pre|math|script|style)\b[^>]*>[\s\S]*?<\/\1\s*>/gi;

const HTML_COMMENT = /<!--[\s\S]*?-->/g;
const HTML_TAG = /<\/?[a-zA-Z][^>]*>/g;
const HTML_ENTITY = /&(?:#\d+|#x[\da-f]+|[a-zA-Z]+);/gi;

/** Strip HTML down to the text a reader actually reads. */
export function htmlToText(html: string): string {
  return html
    .replace(HTML_COMMENT, " ")
    .replace(SKIPPED_BLOCKS, " ")
    .replace(HTML_TAG, " ")
    .replace(HTML_ENTITY, " ");
}

/** CJK characters + Latin words in the given text. */
export function countWords(text: string): number {
  const cjk = text.match(new RegExp(CJK.source, "g"))?.length ?? 0;
  const latin =
    text.replace(new RegExp(CJK.source, "g"), " ").match(LATIN_WORD)?.length ??
    0;
  return cjk + latin;
}

/** Word count of an HTML fragment, ignoring code blocks and math. */
export function htmlWordCount(html: string): number {
  return countWords(htmlToText(html));
}
