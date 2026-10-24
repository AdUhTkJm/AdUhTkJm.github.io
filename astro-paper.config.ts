import { defineAstroPaperConfig } from "./src/types/config";

export default defineAstroPaperConfig({
  site: {
    // GitHub Pages *user* site (repo AdUhTkJm.github.io) → domain root.
    // Keep in sync with blog.toml [site].
    url: "https://AdUhTkJm.github.io",
    base: "/",
    title: "AdUhTkJm",
    description:
      "个人博客。",
    author: "AdUhTkJm",
    profile: "https://github.com/AdUhTkJm",
    ogImage: "default-og.jpg",
    lang: "zh-CN",
    timezone: "Asia/Shanghai",
    dir: "ltr",
  },
  posts: {
    perPage: 10,
    perIndex: 5,
  },
  features: {
    lightAndDarkMode: true,
    // Satori has no CJK glyphs in the bundled font, so a generated OG image
    // would render tofu. Keep this off until a CJK font is wired into satori.
    dynamicOgImage: false,
    showArchives: true,
    showBackButton: true,
    search: "pagefind",
  },
  socials: [
    { name: "github", url: "https://github.com/AdUhTkJm" },
    { name: "mail", url: "mailto:AdUhTkJm@users.noreply.github.com" },
  ],
  shareLinks: [
    { name: "x", url: "https://x.com/intent/post?url=" },
    { name: "telegram", url: "https://t.me/share/url?url=" },
    { name: "mail", url: "mailto:?subject=See%20this%20post&body=" },
  ],
});
