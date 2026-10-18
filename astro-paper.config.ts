import { defineAstroPaperConfig } from "./src/types/config";

export default defineAstroPaperConfig({
  site: {
    // GitHub Pages project site. Keep in sync with blog.toml [site].
    url: "https://AdUhTkJm.github.io",
    base: "/blogs",
    title: "AdUhTkJm",
    description:
      "笔记与随笔：Minecraft 合成规划、杀戮尖塔 2 种子搜索、抽象机、形式化数学。",
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
    scheduledPostMargin: 15 * 60 * 1000,
  },
  features: {
    lightAndDarkMode: true,
    // Satori has no CJK glyphs in the bundled font, so per-post OG images would
    // render tofu. Keep this off until a CJK font is wired into satori.
    dynamicOgImage: false,
    showArchives: true,
    showBackButton: true,
    editPost: {
      enabled: true,
      url: "https://github.com/AdUhTkJm/blogs/edit/main/",
    },
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
