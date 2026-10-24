#set document(title: "Fcitx5 切换输入法时上屏原始文字")
#set page(paper: "a4", margin: 2.3cm)
#set text(size: 10.5pt, font: ("Libertinus Serif", "Noto Serif CJK SC"))
#set heading(numbering: "1.1")
#show link: underline

= 简介

我最近从 Windows 迁移到 Linux，选择的输入法是 fcitx5 以及 Rime。为了迎合我的输入习惯，我进行了各种配置。

== 切换输入法时上屏原始文字

这个功能在 Rime 5.1.9 中引入，然而 `apt get` 只能升级到 5.1.4。

那么自然的想法是从源码编译最新版，但是这个版本依赖 fcitx 5.1.11，而重新编译 fcitx 非常麻烦，要安装一大堆各种各样的依赖。所以，我采取了 backport 的方式，也就是克隆 5.1.4 的源码，把这个特别的部分移植回旧版本，重新编译安装。

剩下的部分就很简单了。大肥鱼很快就可以做好，我自己来也不是不行（就是有点懒）。
