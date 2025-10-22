---
title: 请抵制OpenListApp
date: 2025-10-22 17:53:22 +0800
categories: [OpenList, Third-Party]
tags: [GitHub, Android, Flutter, OpenList, 开源, 软件, 教程]
math: true
description: 请抵制OpenListApp
---


众所周知，Alist被收购后，社区出现了OpenList分支

进而，OpenList下，又出现了很多衍生项目

可是，衍生项目，真的那么好吗？

项目已拥有200+粉丝，OpenListApp也作为关键词收录

![](https://pica.zhimg.com/v2-71a4fe89cb0c6a90671373d77a3ad27e_1440w.jpg)

项目为

[https://github.com/OpenListApp/OpenListApp/github.com/OpenListApp/OpenListApp/](https://link.zhihu.com/?target=https%3A//github.com/OpenListApp/OpenListApp/)

讨论可见：

[https://github.com/OpenListApp/OpenListApp/issues/9github.com/OpenListApp/OpenListApp/issues/9](https://link.zhihu.com/?target=https%3A//github.com/OpenListApp/OpenListApp/issues/9)

![](https://pic2.zhimg.com/v2-dabb0d2bb494052b118ebb85f9ac81c1_1440w.jpg)

先说结论：OpenListApp 是一个声称“开源”，却无视 AGPLv3 开源规则的项目。它在未完整遵循 AGPL 的前提下大量发布含有 AGPL 代码的二进制文件，同时其维护者在被指出问题后，不但拒绝修正，反而选择辱骂和否认。作为一个OpenList开发者，我认为这是对社区的极大不尊重。

我认为有必要揭开这层“挂羊头卖狗肉”的迷雾。

---

## 表面上的“开源项目”，实质上却无许可证、含闭源组件

我对 OpenListApp 最初的注意，来自于它的构建流程。我发现它在打包 Android、iOS、Windows、Linux 应用时，会自动从另一个仓库 [OpenListLib](https://zhida.zhihu.com/search?content_id=260283478&content_type=Article&match_order=1&q=OpenListLib&zhida_source=entity) 下载 AGPLv3 授权的预编译二进制文件。这些二进制包括 .so、.dll、.xcframework、.aar 等，全部被直接集成进最终发布包。

简单点说，用户下载安装 OpenListApp 时，同时也会安装进 OpenListLib，而这个库是 AGPL 授权的。

根据 AGPLv3 的规则，这样的集成是必须开源整个项目的源代码和构建脚本的。AGPL 比 GPL 更严格——只要你通过网络提供服务，使用了 AGPL 组件，你就有义务开源。

![](https://pica.zhimg.com/v2-9d3baffa56a57ef2e3e8e5d81c009e2c_1440w.jpg)

但 OpenListApp 没有这么做。它一开始甚至连许可证都没加上，后面被追问得太多，才仓促加上 MIT，且未对嵌入的 AGPL 库做任何声明。

## 被指出问题后，不是修复，而是公开羞辱

![](https://pic1.zhimg.com/v2-60d1beeecb5b1ba8104e35bb90e20a0c_1440w.jpg)

![](https://pica.zhimg.com/v2-0a0e748b7502a3f112d85cb0076a502e_1440w.jpg)

![](https://picx.zhimg.com/v2-95063ef8c911dd1868ca7e7b8beb59d3_1440w.jpg)

这才是整件事最让人寒心的地方。当我好心提出这些问题时，我得到的不是技术讨论、不是修正态度，而是直接的人身攻击。

他的回应是：“你就是想抄我的项目”“你这种人就是憋不出代码到处抄”……甚至说我“不配提AGPL”。是的，我提出的是一份对AGPL合规的疑问，他的回应却是上纲上线地羞辱、否定、扭曲动机。

他还声称“我就算用了 AGPL 的代码，也只影响我自己写的项目”“AGPL 传染不到别的包”，这种说法不是不懂，而是装糊涂。他作为能熟练使用 [GitHub Actions](https://zhida.zhihu.com/search?content_id=260283478&content_type=Article&match_order=1&q=GitHub+Actions&zhida_source=entity) 自动打包全平台项目的人，不可能不了解动态链接 AGPL 库的法律后果。

说白了，他心知肚明，只是不想开源。

## [pub.dev](https://zhida.zhihu.com/search?content_id=260283478&content_type=Article&match_order=1&q=pub.dev&zhida_source=entity) 上的风险扩散

OpenListApp 的二进制代码还嵌入到 [openlist\_background\_service](https://zhida.zhihu.com/search?content_id=260283478&content_type=Article&match_order=1&q=openlist%5C_background%5C_service&zhida_source=entity) 等 Dart 包中，并发布到了 pub.dev。这意味着——任何用到这些 Dart 包的项目（哪怕是跟 OpenListApp 无关的人）都可能在不知情的情况下，被 AGPL “污染”。

这类“二进制污染”的后果非常严重。只要你发布了一个使用这些包的商业应用，别人就有可能基于 AGPL 条款要求你开源整个项目，而你甚至可能不知道问题出在哪。

开源不是黑箱，而他却把 AGPL 授权的组件当作“编译好的黑箱”偷偷用。这不是“忘了贴个 LICENSE”这么简单，这是在明知故犯的前提下试图规避开源义务。

## 所谓“我只引用了启动器几个文件”的偷换概念

这位维护者还试图通过“我只是引用了两个子项目而已”“只有启动器和入口文件受影响”来淡化责任。

![](https://picx.zhimg.com/v2-95063ef8c911dd1868ca7e7b8beb59d3_1440w.jpg)

这完全是混淆视听。你引用的是 AAR、DLL、SO——它们都是编译后的完整运行库，而且是通过 GitHub Action 全自动集成进包里的。只要你在最终产物中包含了 AGPL 二进制代码，并通过网络提供功能服务，那你整个项目就必须开放源码。这不是你代码有几行受影响的问题，是整合和分发行为本身触发了 AGPL 条款。

我认为，当有人打着开源的旗号，攻击别人，却用 AGPL 代码做闭源集成，并在被指出问题时恶语相向，那我们就必须说“不”。

我不反对商业化，也不反对对抗“传染性”许可证的技术策略。但我反对不守规则却假装开源，甚至反过来羞辱守规则的人。

因此，抵制OpenListApp