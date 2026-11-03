/**
 * Cross-reference terms ↔ glossary entries on Typst note pages.
 *
 * The note source emits, via `#term` / `#glossary` in Typst:
 *
 *   <a class="term" data-term="favilla" href="#glossary-favilla">favilla³</a>
 *   <li id="glossary-favilla" data-term="favilla">…</li>
 *
 * Clicking a term toggles `.is-active` on every element carrying that
 * data-term — the word (and its superscript) plus the annotation it points at,
 * so both light up (styled in src/styles/note.css); clicking again clears it.
 * The anchor's `href` is kept, so without this script the link still jumps to
 * the annotation and the `:target` rule does the highlight.
 */
function setup(): void {
  const root = document.querySelector<HTMLElement>(".note-body");
  // `data-` guard: setup runs once per page load and once per View Transition.
  if (!root || root.dataset.termsReady === "1") return;
  root.dataset.termsReady = "1";

  root.addEventListener("click", event => {
    const link = (event.target as Element | null)?.closest<HTMLElement>(
      "a.term"
    );
    if (!link) return;
    const key = link.dataset.term;
    if (!key) return;

    // No jump: the match is highlighted in place instead.
    event.preventDefault();

    const activating = !link.classList.contains("is-active");
    for (const active of root.querySelectorAll(".is-active")) {
      active.classList.remove("is-active");
    }
    if (!activating) return;

    const selector = `[data-term="${CSS.escape(key)}"]`;
    for (const el of root.querySelectorAll(selector)) {
      el.classList.add("is-active");
    }
  });
}

setup();
document.addEventListener("astro:after-swap", setup);

// Module scope: keeps `setup` from colliding with the global-script theme.ts.
export {};
