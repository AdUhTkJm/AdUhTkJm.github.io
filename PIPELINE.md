# 这个博客是怎么构建的

这是「笔记优先」的静态站点：技术内容不会在这里被改写，`/posts/` 下的笔记页面是从项目仓库中的 Typst 文档编成的快照编译出来的。

## 提交的内容

只有源文件进 git：`blog.toml`（发布白名单）、每篇笔记的快照（单文件是 `sources/<slug>.typ`，多文件文档是目录 `sources/<slug>/`），以及记录每个快照来自哪个上游 commit 的 `sources/provenance.json`。编译出来的 `src/generated/`（HTML）、`public/pdf/`（PDF）、`public/images/`（从页面里抽出来的图）和 `.tools/`（typst 可执行文件）都不提交。

快照是唯一的构建输入。`scripts/compile.py` 始终编译快照（`sources/<slug>.typ` 或 `sources/<slug>/<entry>`），从不碰项目仓库里的原始文档，这带来三点：没有任何生成物进入版本控制——历史上不会有 700 KB 的 PDF，也不存在与固定版本编译器、自包含源文件相重复的 HTML；新克隆在没有任何项目的环境上也能得到完全一致的构建（已逐字节验证过：`$HOME` 指向不含 `~/projects` 的目录的克隆，HTML 和 PDF 都一样）；CI 不需要访问项目仓库，也不需要任何密钥。代价是构建现在需要 typst（约 40 MB 的下载，有缓存），而不再只需要 Node。

```
blog.toml                         精选的发布白名单：哪些文档会公开
sources/<slug>.typ                单文件笔记的快照（构建输入）
sources/<slug>/                   多文件笔记的整棵目录快照（构建输入）
sources/provenance.json           每个快照来自哪个上游 commit + 文件哈希
scripts/compile.py                快照 -> HTML（MathML）+ PDF + 抽出的图
compile.sh                        唯一会运行的命令
src/lib/notes.ts                  对生成清单的带类型访问器
src/lib/articles.ts               统一文章模型（笔记 + Markdown 随笔）
src/pages/posts/[...slug]/        文章渲染器（笔记 + 随笔，URL 统一为 /posts/）
src/styles/note.css               与 PDF 镜像一致的屏幕排版
```

## 日常使用

```
./compile.sh
./compile.sh --dev
./compile.sh --check
```

第一个刷新快照、编译并构建；`--dev` 之后还会启动 `astro dev`；`--check` 只检查快照与线上文档是否还同步（目录快照逐文件比哈希）。

`compile.sh` 是 `pnpm build` 的薄封装，而 `pnpm build` 会先运行 `scripts/compile.py`，所以无法直接调用 pnpm 绕过流水线。首次运行会把固定版本的 `typst` 下载到 `.tools/`；你系统上的 `typst` 不会被使用，所以它的版本无关紧要。

每个克隆仓库启用一次这个安全网：

```sh
git config --local core.hooksPath .githooks
```

之后 `git push` 会拒绝推送与源文件不一致的快照。

## 加一篇笔记

首先在文档所在的项目仓库中撰写或编辑文档（例如 `~/projects/seedsearch/docs/optimizations.typ`）；然后在 `blog.toml` 中添加 `[[note]]` 块；接着运行 `./compile.sh`，它会把文档复制到 `sources/`、把 commit 记录进 `sources/provenance.json` 并构建；最后提交 `blog.toml` 和 `sources/`。

文档自身的标题块与页面设置会被 HTML 导出器忽略；`title`、`summary`、`date`、`tags` 都取自 `blog.toml`。

单文件笔记的快照必须是自包含的：`#import "other.typ"` 引用的文件不会进入快照，所以 `compile.py` 一旦遇到相对导入或 include 就会报错。使用包（`@preview/cuti`、`@preview/cetz`）没问题，它们在构建时从 Typst Universe 解析。要发布拆成多个文件的文档，用下面的目录快照。

## 多文件文档

毕业论文（`~/llvm/dissertation`）那样拆成 `chapters/` + `diagrams/` + `images/` 的文档，把 `source` 指向**目录**、再用 `entry` 指明从哪个文件编译：

```toml
[[note]]
source = "~/llvm/dissertation"
entry = "web.typ"
exclude = [".vscode", ".codex", "presentation", "raw-data", "scripts", "build/*.pdf", "*.sh", "*.md"]
shim = ["diagram"]
slug = "compiler/cache-miss-analysis"
```

整棵目录（减去 `.git` 和 `exclude`）都会复制进 `sources/<slug>/`，`--check` 逐文件比哈希，所以快照仍然可以审计。`entry` 必须是**一个**根文件，这不是偷懒：第 2 章引用了第 3、4 章的 label（`@barvinok-impl`、`@eval`），把它们拆成独立编译单元只会留下一堆悬空引用。网页上的「一章一页」需要先整体编译再切 HTML，目前没做；现在是一个长页 `/posts/compiler/cache-miss-analysis/`（1.5 MB HTML，gzip 后 226 KB，51,000 px 高）。

入口文件写在上游仓库里（`dissertation/web.typ`），因为它要表达的是内容决策：包含哪几章、编号从 2 开始（`#counter(heading).update(1)`）、`= Evaluation <eval>` 这个 label 挂在哪、`#bibliography("ref.bib")`。翻译版只要再写一个 `web_zh.typ`（`#include "chapters/preparation_zh.typ"`），然后在 `blog.toml` 里加一个 `entry = "web_zh.typ"` 的 `[[note]]` 即可，路径和章节数都不必与英文版一致。

`exclude` 是显式列表而不是自动推断：`build/repo.typ`（`make.sh` 生成的行数统计）必须留在快照里，`build/*.pdf` 必须排除，两者在同一个目录下，只有人知道区别。

## 为什么 Typst 直接导出 HTML

Typst 0.15 把公式导出为 MathML、表格导出为 `<table>`、交叉引用导出为锚点、脚注导出为 `role="doc-endnotes"`。这样一来就没有 Typst → Markdown → LaTeX 这条转换链要维护了，页面上也没有 KaTeX 的包。

两点需要注意。其一，0.15 之后才导出公式，0.14 会静默丢掉公式；`compile.py` 对源文件含 `$` 但输出没有 `<math>` 的情况会报错，错误的 typst 版本就混不进去。其二，`--features html` 官方标记为不稳定，所以 `blog.toml` 里固定了版本，升级 typst 是有意识的事情。升级后应比对渲染的页面（或 `sources/` + 新旧编译器），而不是对生成 HTML 做 diff——那些已经不进版本控制了。

分页专用指令（`page`、`align`、分页）在 HTML 中会被忽略，这也是同一份源文件同时会编译出 PDF 的原因。

## 交互部件与图表

Typst 画的图在 HTML 导出里有个坑：`html.frame(canvas(...))` 会渲染为内联 SVG，**裸** `cetz.canvas(...)` 会被静默丢掉，只留下 caption。fletcher 的 `diagram` 同理，`#scale(...)` 包在外面时连 frame 一起吞掉。

手改 28 个上游图文件不现实（而且译文会再抄一遍），所以 `shim = ["diagram"]` 会让 `compile.py` 在**临时构建树**里做三处 token 级改写，`sources/` 里始终是上游原文：

```
#import "@preview/cetz:0.4.2"            ->  #import "/_blog_shim/0-4-2/cetz.typ"
#import "@preview/fletcher:0.5.8": *     ->  #import "/_blog_shim/0-5-8/fletcher.typ": *
#scale(x: 85%, y: 85%, reflow: true)[    ->  #web-scale(...)[
```

改写的是 **import 绑定**，不是调用点。生成的 shim 模块是「原包的全部导出 + `canvas` 换成 `html.frame(canvas(..args))`」，所以文档里写 `cetz.canvas`、`f.diagram`、`import ...: *` 之后直接 `canvas(...)`，全都不用管。文件 stem 必须是包名（typst 用文件名推导隐式绑定，`cetz-0-4-2.typ` 会直接语法错误），版本放在目录名里，两个文档用不同 cetz 版本也不会撞车。`#scale` 的 `#` 前缀正好把 markup 层的调用和 canvas 内部 cetz 自己的 `scale()` 区分开，不需要括号配对。

为什么不上 AST：typst 的语法树只在 Rust 里（`typst-syntax`），没有 Python 绑定，为一条正则引入 Rust 依赖不划算。代价是改写是启发式的，所以 `compile.py` 加了硬断言：**每个 `<figure>` 必须含 `<svg>` 或 `<img>`**，否则带着 caption 直接报错——静默失败的图在 27 张里一抓就准，比事后肉眼检查可靠。

图片不会被 base64 卡在页面里：导出器给的 `data:image/png;base64,...` 会被抽到 `public/images/<slug>/`，文件名靠「payload 与快照里的文件逐字节相同」还原，所以还是 `miss-mine-to-perf-log.png` 而不是一串哈希。单页因此从 2.0 MB 降到 1.5 MB，且图可以被浏览器缓存。

Typst 文档也可以为 JavaScript 留一个挂载点：

```typst
#html.elem("div", attrs: (class: "widget", "data-widget": "rng-stream"))
```

之后前端脚本就能给每个 `[data-widget]` 挂上交互。还没实现——骨架里现在还没有部件。

## 部署

`.github/workflows/deploy.yml` 运行 `pnpm build`（会编译快照）并发布 `dist/`。GitHub 仓库里设置 Settings → Pages → Source: GitHub Actions。

两个 CI 细节。`fonts-noto-cjk` 装在 CI 里：HTML 输出与字体无关（已验证过，关掉系统字体后输出逐字节一致），但 PDF 不是——没有中文字体时 typst 会回退到拉丁字体，中文变成豆腐块；`Libertinus Serif` 不用装，它包含在 typst 可执行文件里。另外 `.tools/` 有缓存，key 由 `blog.toml` 派生，所以 typst 只在固定版本变了时才会下载。

项目站点（仓库 `blogs`，URL `/<user>.github.io>/blogs/`）：`base = "/blogs"`。用户站点（仓库 `<user>.github.io`）：`base = "/"` 要设在 `blog.toml` 和 `astro-paper.config.ts` 两处。

`base` 配错的症状很好认，因为 Astro **不会**把 `base` 写进构建产物路径：`dist/` 里仍然是 `index.html`、`posts/...`，而 HTML 里的资源指向 `/<base>/_astro/...`。上传的是 `dist/`、由 Pages 挂在域名根上，于是 CSS 全部 404（裸 HTML 的样子），文章链接也全 404（页面显示“不存在”），但 `pnpm preview` 一切正常——因为 preview 会真的在 `/<base>/` 下提供服务。

## 踩过的坑

永远不要给 `<math>` 设 `display`。UA 样式表给 `math[display=block]` 的值是 `block math`，正是 `math` 这半段让 MathML 排版子元素；用 `display: block` 覆盖会让 `mi`、`mo`、`mfrac` 变成普通块级盒子，公式就坍缩成一列垂直的符号。所以 `compile.py` 把显示式公式包进 `<div class="math-block">`——滚动需要一个块级盒子，但必须是外层容器，不能是 `math` 本身。

表格要同时有 `code { white-space: nowrap }` 和单元格下限。没有 `nowrap`，标识符会在词中间断（`NextUnsignedInt(m` / `in,max)`）；只有 `nowrap` 时，表格最小内容超过列宽，浏览器会把中文列压到每行一个字——所以 `td`/`th` 也加了 `min-width: 4em`，改由 `.table-wrap` 横向滚动。

`text-muted` 是背景色不是文字色。主题为背景提供 `--muted` (#e6e6e6)，为文字提供 `--muted-foreground` (#6b7280)；用 `text-muted` 会得到几乎看不见的白底灰字。

锚点链接是平滑滚动的：`<html>` 上开了 `scroll-smooth`，一条 hash 链接进入 13,000 px 的文档要等约 2 秒的动画才到。行为是对的，就是慢；嫌烦就删掉 `scroll-smooth`。

## 视觉验证

布局是用无头 Chromium 查的，不是肉眼。要重复这个过程：

```sh
./compile.sh && pnpm preview
```

之后用打印出的 URL 打开。有几点可以断言：显示式公式 `getComputedStyle(m).display` 应为 `"block math"` 且子元素分布在多个 `x` 位置；没有比 ~3em 更窄的 `td`；390 px 视口下 `document.documentElement.scrollWidth === innerWidth`。

## 已知缺口

`compile.py` 目前只处理 `.typ`；`.md` 文档（比如 llama.cpp 那篇）还没有直通内容集合的路径。diagram shim 只覆盖 cetz 的 `canvas` 和 fletcher 的 `diagram`：上游如果改用别的绘图包、或在 markup 层用 `#scale` 之外的分页指令包图，断言的报错会指到具体 caption，但修法要自己加一条规则。站点依赖系统衬线字体显示中文，不打包约 8 MB 的 Noto CJK webfont（PDF 不受影响，CI 装了字体）。OG 图片（`dynamicOgImage`）关着，因为 satori 内置字体没有中文字形。Pagefind 给文章页打了索引（`data-pagefind-body`），但中文没有 stemming。island 流水线已搭好（Astro），不过目前没人用。AstroPaper 的示例文章已删，`src/content/posts/hello.md` 是剩下的唯一一篇。

## 升级 typst

改 `blog.toml` 的 `[typst] version`，然后 `rm .tools/typst.version` 强制重新下载（顺带使 CI 缓存 key 失效），再运行 `./compile.sh`，看控制台警告和渲染的页面、PDF。生成物不再进版本控制，没有 diff 可看——编译器版本就是约定。
