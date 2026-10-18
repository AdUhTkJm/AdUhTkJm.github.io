---
title: "关于"
description: "关于这个站点，以及它是怎么被构建出来的。"
---

## 我是谁

写 C++、TypeScript 和一些 Typst。感兴趣的方向：组合优化在游戏规则上的应用、逆向游戏内部的随机数实现、抽象机与形式化数学。

## 这里有什么

- **[笔记](/notes/)** —— 按项目分组的长期文档。它们不是为博客写的，而是各项目 `docs/` 目录里的原文，由 Typst 直接编译成网页。数学公式是 MathML，图表是矢量图，每篇另有 A4 排版的 PDF。
- **文章** —— 短一些、按时间排列的叙述性内容。

## 站点是怎么做出来的

内容管线只有三步：`blog.toml` 声明要发布哪些文件，`scripts/compile.py` 调用钉死版本的 Typst 把它们编译成 HTML 和 PDF，[Astro](https://astro.build/) 套上主题模板并输出静态站点。

主题是 [AstroPaper](https://github.com/satnaing/astro-paper)，托管在 GitHub Pages 上。设计是现成的，不是我自己画的。
