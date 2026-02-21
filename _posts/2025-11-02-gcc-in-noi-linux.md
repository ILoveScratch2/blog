---
title: "NOI Linux 上的 G++ 编译器"
date: 2025-11-02 21:55:01 +0800
categories: [技术, Linux]
tags: [G++, 编译器, 教程]
description: 介绍 NOI Linux 上的 G++ 编译器使用方法
---

> 软件仅用于学习交流与局域网团队协作，~~上课认真听讲更重要~~ ~~水题也可以不听~~

**如果觉得 TouchFish Astra 好用，请点个 Star PLZ（~~没错我和 TouchFish 一样是来讨 star 的~~）。如果您在使用 TouchFish Astra 的时候遇到 bug，请在本文章下提出或去 Issue 提，如果您想给 TouchFish Astra 添砖加瓦，请提交 PR，感谢支持！**

还记得机房里那种「外网断了、需求不断」的时刻吗？需要一个能在内网里稳定沟通的小工具，既能发文字，又能发文件，最好还能有 Markdown/LaTeX 展示作业思路，UI 还得好看一点。于是就有了 [TouchFish](https://www.luogu.com.cn/article/z6se69kk)。

但是 TouchFish 的 CLI 不够直观，Tkinter GUI 不够美观…… 社区的界面又不够兼容……怎么办呢？

于是就有了 TouchFish Astra——一个基于 Flutter 的跨平台 TouchFish 客户端，支持 Windows、Linux、macOS 和 Android，轻量、稳定、颜值在线。

- 如果你用过 TouchFish、TouchFish UI Remake、TouchFishPro，那么 Astra 既延续了「轻 + 快」的特点，也带来更现代的 UI 和更完善的日常体验。

GitHub：https://github.com/ILoveScratch2/TouchFish-Astra

下载：https://github.com/ILoveScratch2/TouchFish-Astra/releases/

也可使用加速：[APK（Android）](https://ghproxy.net/https://github.com/ILoveScratch2/file/releases/download/astra/android.apk) [LINUX](https://ghproxy.net/https://github.com/ILoveScratch2/file/releases/download/astra/linux.gz) [MACOS](https://ghproxy.net/https://github.com/ILoveScratch2/file/releases/download/astra/macos.zip) [WINDOWS](https://ghproxy.net/https://github.com/ILoveScratch2/file/releases/download/astra/windows.zip)

---

## 截图

![](https://cdn.luogu.com.cn/upload/image_hosting/w2swt3ay.png)

![](https://cdn.luogu.com.cn/upload/image_hosting/d70dlsxt.png)

![](https://cdn.luogu.com.cn/upload/image_hosting/mstjjrhu.png)

![](https://cdn.luogu.com.cn/upload/image_hosting/0vuppxmb.png)

![](https://cdn.luogu.com.cn/upload/image_hosting/0vxe6pli.png)

---

## 它能做什么？

- 跨平台：Windows / Linux / macOS / Android 全覆盖，一套 UI 风格一致。（macOS 没设备测试理论能用，具体咋样难说）
- 即连即用：输入 IP 和端口即可连接兼容的 TouchFish 服务端，零门槛。
- 聊天体验：
  - 发送文本、文件，接收文件
  - 支持 Markdown/LaTeX 渲染（公式党福音）
  - 消息气泡（多行消息有亿点问题）、主题色、暗/浅色主题切换
- 个性化和可配置：
  - 高度自定义设置
  - 多语言支持
- 管理与扩展：
  - 管理员功能（适合集中管理）
  - 与 TouchFish 服务端兼容，便于接入现有环境

一句话：把「能用」变成「好用」。

---

## 优点

更好的 UI 细节：Material Design 风格、布局清爽、交互自然；对比一些传统轻量工具的「能跑就行」，Astra 更注重视觉一致性和使用舒适度。

- 功能聚焦「本地协作」：
  - 局域网聊天优先，延迟低、依赖少
  - Markdown/LaTeX 让「学术讨论/作业交流」更顺手
  - 文件传输满足快速同步资料的刚需

---

## 猪包猪包，怎么不开发一个新的聊天工具呢？

~~肯定不是因为作者太菜了不会服务端~~

因为现有的 TouchFish 已经够用且生态完善，没有必要开发新的。

~~未来大概会有 CloudStudio Astra 吧~~

适合机房/课堂/社团的局域网交流。

## 快速开始

1. 下载
   - 前往项目 Releases 页面，选择你的平台，下载对应的安装包/可执行文件。
2. 连接服务端
   - 使用正在运行的 TouchFish 或其他兼容服务端（可在局域网或公网部署）。
   - 获取服务端的 IP 和端口。
3. 启动客户端并连接
   - 输入 IP、端口、用户名，连接后即可聊天。
4. 发消息/传文件
   - 聊天框输入文本即可发送。
   - 支持 Markdown/LaTeX 渲染。
   - 直接选择文件即可传输。

各平台提示：

- Windows：将压缩包完整解压到同一目录后再运行（不要在压缩包内直接双击 EXE）。
- macOS：运行可能需要允许「来自未认证开发者的应用」；在「系统设置-隐私与安全」放行。
- Linux：解压即可运行（部分发行版可能需要安装系统依赖）。
- Android：提供 APK（直接安装）和 AAB（应用商店/侧载用），普通用户建议下载 APK。

---

## 管理员功能（可选）

- 需要在服务端端有管理员权限。
- 可以进行用户管理、公告发布等基本操作。
- 适合教室/社团集中管理、统一通知。

---

## 和其他生态项目的关系

- 兼容生态：Astra 是 TouchFish 生态的跨平台客户端，直接接上兼容的服务端即可用。
- 使用门槛更低：UI 和设置更贴近「桌面/移动应用」的直觉，适合非技术用户。

并不是「谁取代谁」，而是针对不同场景的互补。

---

## 常见问题（FAQ）

- Q：必须自己搭服务端吗？
  - A：不一定。只要你所在的环境有人已在局域网跑了 TouchFish 或兼容服务端，你直接连接就行。
- Q：能离线用吗？
  - A：聊天需要与服务端连通（局域网或公网均可）。
- Q：为什么我双击不运行？
  - A：Windows 常见原因是「没解压到同一目录」，别直接双击运行了。
  - 而且老系统兼容性不一定好……
  - 其他系统看情况而定。

---

## 开源与贡献

- 许可证：AGPL-3.0

如果你愿意，给项目点个 Star，会是继续迭代的动力。