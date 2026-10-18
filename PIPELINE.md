# AdUhTkJm 的博客

一个存放笔记的静态站点。HTML 页面由存放在项目仓库中的 Typst 文档的快照编译而成。

## 提交的内容及其原因

| 提交 | 不提交 |
|---|---|
| `blog.toml` — 发布白名单 | `src/generated/` — 编译后的 HTML |
| `sources/<slug>.typ` — 每篇笔记一个快照 | `public/pdf/` — 编译后的 PDF |
| `sources/provenance.json` — 每个快照对应的上游 commit | `.tools/` — typst 可执行文件 |

快照是**唯一的构建输入**。`scripts/compile.py` 始终编译 `sources/<slug>.typ`，从不直接编译项目仓库中的原始文档，这带来三个好处：

代价是构建现在需要 typst（约 40 MB 的下载，有缓存）而不再只需要 Node。

```
blog.toml                         精选的发布白名单：哪些文档会公开
sources/<slug>.typ                每篇已发布文档的快照（构建输入）
sources/provenance.json           每个快照源自哪个上游 commit
scripts/compile.py                快照 -> HTML（MathML）+ PDF
compile.sh                        你唯一会运行的命令
src/lib/notes.ts                  对生成清单的带类型访问器
src/pages/notes/                  索引页 + [...slug].astro 渲染器
src/styles/note.css               与 PDF 镜像一致的屏幕排版
```

## 日常使用

```sh
./compile.sh          # 刷新快照，编译，构建
./compile.sh --dev    # 同上，之后再运行 `astro dev`
./compile.sh --check  # 快照是否仍与线上文档同步？
```

`compile.sh` 是 `pnpm build` 的薄封装，而 `pnpm build` 会先运行
`scripts/compile.py`——因此无法通过直接调用 pnpm 来跳过该流水线。首次运行
会将固定版本的 `typst` 下载到 `.tools/`；你系统上的 `typst` 永远不会被使用，
因此其版本无关紧要。

每个克隆仓库只需启用一次安全网：

```sh
git config --local core.hooksPath .githooks
```

从此 `git push` 会拒绝推送与源文件已不一致的快照。

## 添加一篇笔记

1. 在其项目仓库中撰写或编辑文档（例如
   `~/projects/seedsearch/docs/optimizations.typ`）。
2. 在 `blog.toml` 中添加 `[[note]]` 块（或编辑已存在的块）。
3. 运行 `./compile.sh`——这会复制文档到 `sources/`，将其 commit 记录在
   `sources/provenance.json`，并执行构建。
4. 提交 `blog.toml` 和 `sources/`。

文档自身的标题块与页面设置会被 HTML 导出器忽略；`title`、`summary`、
`date` 和 `tags` 均由 `blog.toml` 提供。

快照必须是**自包含**的：`#import "other.typ"` 引用的其他文件不会被纳入快照，
因此 `compile.py` 一旦遇到相对导入或 include 就会明确报错。使用包（
`@preview/cuti`、`@preview/cetz`）没有问题——它们在构建时从 Typst Universe
解析。

## 为什么 Typst 直接导出 HTML

Typst 0.15 将公式导出为 **MathML**、表格导出为 `<table>`、交叉引用导出为锚点、
脚注导出为 `role="doc-endnotes"`。因此没有需要维护的 Typst → Markdown →
LaTeX 转换链，页面上也没有 KaTeX 打包脚本。

需要知道的两点：

- **0.15 之后才导出公式。** 0.14 会静默丢弃公式。若源文件包含 `$` 而输出中
  没有 `<math>`，`compile.py` 就会明确报错，错误的 typst 版本便无法蒙混过关。
- **`--features html` 官方仍标记为不稳定。** 因此 `blog.toml` 中固定了版本；
  升级 typst 是一项刻意的操作。升级时应比对渲染后的站点（或 `sources/` +
  新旧编译器），而不是对已不再纳入版本控制的生成 HTML 做 diff。

仅用于分页的指令（`page`、`align`、分页）在 HTML 中会被忽略——这也是同一
份源文件会同时被编译为 PDF 的原因。

## 交互式部件与图表

- Typst 绘制的图表需要包裹：`html.frame(canvas(...))` 会渲染为内联 SVG。
  单独的 `cetz` 画布会被 HTML 导出器**静默丢弃**。
- Typst 文档可以为 JavaScript 预留挂载点：

  ```typst
  #html.elem("div", attrs: (class: "widget", "data-widget": "rng-stream"))
  ```

  之后前端脚本可以挂载（hydrate）每个 `[data-widget]`。尚未实现——当前骨架中
  还没有任何部件。

## 部署

`.github/workflows/deploy.yml` 会运行 `pnpm build`（会编译快照）并发布
`dist/`。在 GitHub 仓库中：**设置 → Pages → 来源：GitHub Actions**。

两个 CI 细节：

- **CI 中安装了 `fonts-noto-cjk`。** HTML 输出与字体无关——已验证：抑制系统
  字体后输出逐字节一致——但 PDF 输出不是。没有中文字体时，typst 会回退到
  拉丁字体，中文变成豆腐块。`Libertinus Serif` 无需安装；它包含在 typst
  可执行文件内。
- **`.tools/` 会缓存**，缓存键由 `blog.toml` 派生，因此 typst 的下载仅在
  固定版本变化时发生。

- 项目站点（仓库 `blogs`，URL `/<user>.github.io>/blogs/`）：`base = "/blogs"`。
- 用户站点（仓库 `<user>.github.io`）：在 `blog.toml` 和
  `astro-paper.config.ts` 两处都设为 `base = "/"`。

## 踩过的坑

**永远不要给 `<math>` 设置 `display`。** UA 样式表给
`math[display=block]` 的值是 `block math`；正是 `math` 这半段让 MathML 能够
排版其子元素。用 `display: block` 覆盖它，会把 `mi`、`mo`、`mfrac` 变成
普通的块级盒子，整个公式就坍缩成一列垂直排列的符号。正因如此，`compile.py`
把显示式公式包裹进 `<div class="math-block">`——滚动需要一个块级盒子，但这个
盒子必须是*外层容器*，绝不能是 `math` 本身。

**表格同时需要 `code { white-space: nowrap }` 和单元格下限。** 没有
`nowrap`，标识符会在词中间断开（`NextUnsignedInt(m` / `in,max)`）。仅有
`nowrap` 时，表格的最小内容会超过列宽，浏览器会把中文文本列压到每行一个字符——
因此 `td`/`th` 也设置了 `min-width: 4em`，让 `.table-wrap` 横向滚动代替。

**`text-muted` 是背景色，不是文字色。** 主题为背景提供了 `--muted` (#e6e6e6)，
为文字提供了 `--muted-foreground` (#6b7280)。用 `text-muted` 会得到几乎看不
见的白底灰字。

**锚点链接使用平滑滚动。** `<html>` 上开启了 `scroll-smooth`，因此一条 hash
链接进入 13,000 px 长的文档时，要经历约 2 秒的动画才到达。行为正确，就是
慢；觉得烦的话删掉 `scroll-smooth` 即可。

## 视觉验证

布局是用无头 Chromium 检查的，不是肉眼看的。要重复这个过程：

```sh
./compile.sh && pnpm preview        # 之后使用打印出的 URL
```

有用的不变量：显示式公式应满足
`getComputedStyle(m).display === "block math"`，且其子元素分布在多个 `x`
坐标位置；没有比 ~3em 更窄的 `td`；在 390 px 视口下
`document.documentElement.scrollWidth === innerWidth`。

## 已知缺口

| 缺口 | 说明 |
|---|---|
| Markdown 源 | 目前 `compile.py` 只处理 `.typ`；`.md` 文档（如 llama.cpp 那篇）需要一个直通路径接入内容集合。 |
| 站点的中文字体 | 站点依赖系统衬线字体渲染中文，而非打包约 8 MB 的 Noto CJK 网络字体。（PDF 不受影响：CI 安装了该字体。） |
| OG 图片 | `dynamicOgImage` 已关闭：satori 内置的字体没有中文字形。 |
| 搜索 | Pagefind 对 `/notes/` 页面做了索引（`data-pagefind-body`），但没有中文 stemming。 |
| 尚无部件 | island 流水线已搭好（Astro），但还没有任何代码使用它。 |
| 删除了演示文章 | AstroPaper 的示例文章已被移除；`src/content/posts/hello.md` 是唯一的文章。 |

## 升级 typst

1. 修改 `blog.toml` 中的 `[typst] version`。
2. 执行 `rm .tools/typst.version`（强制重新下载；同时使 CI 缓存键失效）。
3. 运行 `./compile.sh`，阅读控制台警告，然后查看渲染后的页面和 PDF。
