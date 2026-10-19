---
title: "把散落各处的文档收进一个站点"
author: AdUhTkJm
pubDatetime: 2026-10-18T00:00:00Z
featured: true
draft: true
tags: ["meta", "typst", "astro"]
description: "这个博客的构建方式：Typst 源文件直接生成网页，一份源码同时产出 HTML、MathML 和 PDF。"
---

这个站点上的技术内容并不是重新写一遍的。它们从各个项目的 `docs/` 目录直接编译而来。

## 一篇笔记的旅程

以 [地图路径剪枝](/notes/seedsearch/map-path-pruning) 为例，源文件是 `~/projects/seedsearch/docs/optimizations.typ`。运行一次 `./compile.sh` 之后：

1. Typst 的 HTML 导出器把它变成语义化的 HTML，公式成为 MathML，表格成为 `<table>`，交叉引用成为锚点；
2. 同一份源码再编译一次 A4 版式，得到可打印的 PDF；
3. 源文件被快照到 `sources/`，生成的页面提交到 `src/generated/`。

于是这个仓库永远不需要一份项目的完整副本，GitHub Actions 也不需要访问那些仓库。

## 为什么不是 Markdown

因为内容是数学。把 Typst 转成 Markdown 再转成 LaTeX 再交给 KaTeX，每一步都会丢掉一些东西，而且需要维护一个转换器。直接让 Typst 输出 MathML，两边都是机器可读的，浏览器也原生渲染。

代价是 **typst 0.15 之前公式会被静默丢弃** —— 所以版本被钉死在 `blog.toml` 里，`compile.py` 也检查这一点。

## 想加一篇笔记

在 `blog.toml` 里加一个 `[[note]]`，跑 `./compile.sh`。仅此而已。
