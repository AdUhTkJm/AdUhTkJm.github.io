# AdUhTkJm 的个人博客

这是存放我文章的静态博客。笔记与随笔在站点上统一为「文章」，不再按源格式区分。构建方式：

```sh
./compile.sh
pnpm preview
```

源文件是项目文件的快照，虽然也算是生成（复制）的文件，不过会放进 git。其他的 HTML 网页、PDF 等编译产物则自动构建。

文档由 `blog.toml` 中的 `[[note]]` 块声明。具体的工作原理可见[PIPELINE.md](./PIPELINE.md)。

基于 [Astro](https://astro.build/) 与 [AstroPaper](https://github.com/satnaing/astro-paper) 主题构建。

笔记正文通过 Typst 编译为 HTML，其中公式由 MathML 显示。
