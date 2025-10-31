---
title: 使用国内源加速 RubyGems 安装
date: 2025-10-31 17:37:33 +0800
categories: [网站建设]
tags: [GitHub, Chirpy, RubyGems, Bundler]
math: true
description: RubyGems，Bundler替换为国内镜像
---


# Gems

```bash
gem sources --add https://mirrors.tuna.tsinghua.edu.cn/rubygems/ --remove https://rubygems.org/ # 替换为清华源
gem sources -l # 列出当前源，确认替换成功
```

# Bundler


```bash
bundle config mirror.https://rubygems.org https://mirrors.tuna.tsinghua.edu.cn/rubygems
```
