/**
 * CJK character count for prose written in Chinese, Japanese or Korean.
 *
 * Counting rules — the ones Chinese editors actually use for 字数:
 *   - every CJK character counts as one 字;
 *   - whitespace, punctuation, markup, Latin letters and digits count as
 *     nothing.
 *
 * Blocks that are not prose are skipped before counting:
 *   - code (`<pre>` and inline `<code>`);
 *   - `<math>` blocks (raw MathML would count every symbol in an equation);
 *   - `<svg>` (figure labels are not article text), `<script>` and `<style>`.
 */
const CJK =
  /[\u2e80-\u2fff\u3005\u3007\u3021-\u3029\u3040-\u30ff\u3400-\u4dbf\u4e00-\u9fff\uf900-\ufaff\uac00-\ud7af]/;

/** Elements whose text content must never be counted. */
const SKIPPED_BLOCKS =
  /<(pre|code|math|script|style|svg)\b[^>]*>[\s\S]*?<\/\1\s*>/gi;

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

/** CJK characters in the given text. */
export function countCjk(text: string): number {
  return text.match(new RegExp(CJK.source, "g"))?.length ?? 0;
}

/** CJK count of an HTML fragment, ignoring code, math and SVG. */
export function htmlCjkCount(html: string): number {
  return countCjk(htmlToText(html));
}
