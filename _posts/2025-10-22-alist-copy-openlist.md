---
title: AList抄袭OpenList代码，践踏开源精神
date: 2025-10-22 19:00:00 +0800
categories: [OpenList, Third-Party]
tags: [GitHub, AList, OpenList, Dev, 开源, 软件]
math: true
description: AList抄袭OpenList代码，践踏开源精神
---


事件PR

[feat: add support 123open by skysliences · Pull Request #9217 · AlistGo/alistgithub.com/AlistGo/alist/pull/9217](https://link.zhihu.com/?target=https%3A//github.com/AlistGo/alist/pull/9217)

存档：  
[feat: add support 123open by skysliences · Pull Request #9217 · AlistGo/alist · GitHu](https://link.zhihu.com/?target=https%3A//web.archive.org/web/20250725142304/https%253A%252F%252Fgithub.com%252FAlistGo%252Falist%252Fpull%252F9217)b

[feat: add support 123open by skysliences · Pull Request #9217 · AlistGo/alist · GitHub](https://link.zhihu.com/?target=https%3A//web.archive.org/web/20250725142318/https%3A//github.com/AlistGo/alist/pull/9217/files)

[https://wwrv.lanzn.com/im4M131xolkd](https://link.zhihu.com/?target=https%3A//wwrv.lanzn.com/im4M131xolkd)

密码:7obk

## 一、事件回顾：PR #9217，是“借鉴”还是“偷窃”？

Alist 最初由 [Xhofe](https://zhida.zhihu.com/search?content_id=260872113&content_type=Article&match_order=1&q=Xhofe&zhida_source=entity) 创立，遵循 AGPL-3.0 协议，以“极简网盘列表聚合工具”走红，曾斩获 48.5k GitHub Star。然而，自 2025 年 6 月 Xhofe 宣布将项目整体移交[不够科技](https://zhida.zhihu.com/search?content_id=260872113&content_type=Article&match_order=1&q=%E4%B8%8D%E5%A4%9F%E7%A7%91%E6%8A%80&zhida_source=entity)以来，社区信任迅速崩塌，多位核心开发者退出，并发起去商业化的分叉项目 [OpenList](https://zhida.zhihu.com/search?content_id=260872113&content_type=Article&match_order=1&q=OpenList&zhida_source=entity)。

就在 OpenList 逐步建立口碑，获得 13.1k Star 与超 200 位贡献者之时，Alist 团队的 PR #9217 将事态推向高潮：@skysliences 提交的代码直接照搬 OpenList 部分模块，完全未标注来源或版权信息。

对比OpenList代码，除依赖外无任何差别

![](https://pic3.zhimg.com/v2-eed23d91e353788dcdb33f9f1e846b0e_1440w.jpg)

当社区指出该行为违反 AGPL 协议、涉嫌代码侵权时，@skysliences 并未作出任何解释或修正，反而回应称：

> “开源代码为啥不能 Copy？”  
> “你有本事自己提 PR，别 BB。”

![](https://pic2.zhimg.com/v2-b280519739b85617726847d051ca97d1_1440w.jpg)

一句“Copy”口号，彻底击穿了开源的底线。

## 二、不够科技：从“供应链污染”到“协作污染”

### 1. 抄袭代码，违反 AGPL-3.0，已构成协议侵权

AGPL-3.0 是业界最具“传染性”的开源协议之一，其明确规定：

- **所有修改代码**必须开源；
  
- **所有部署行为**必须公开源码；
  
- **所有使用 AGPL 模块的项目**，必须保留原始版权信息与协议声明。
  

PR #9217 明显未满足任何一项。OpenList 的模块经过重构与安全审计，包含大量独创性设计，属于典型“非机械性复制”。而 Alist 所谓“Copy”，更像是对社区劳动成果的赤裸掠夺。

### 2. 社区质疑遭删帖，项目治理走向封闭

自从不够科技接手 Alist 后，其项目治理日趋“公司化”

此次 @skysliences 抄袭风波后，遭到删帖处理，反对声音被屏蔽，“Copy 党”言论却被默认接受。这种倒挂的“道德准则”，正在让原本开放的社区逐步沦为企业的私有工具。

### 3. 不够科技“黑历史”：被社区戏称为“开源收割机”

自 2023 年成立以来，不够科技频频收购国内热门开源项目，包括但不限于：

- [Hutool](https://zhida.zhihu.com/search?content_id=260872113&content_type=Article&match_order=1&q=Hutool&zhida_source=entity)
- [Oneinstack](https://zhida.zhihu.com/search?content_id=260872113&content_type=Article&match_order=1&q=Oneinstack&zhida_source=entity)
- LNMP 一键包  
  几乎每个项目被其接手后，都逐步走向闭源化、商业化、文档篡改与社区封闭化。Alist 显然正在重蹈覆辙。

## 致 @skysliences 和不够科技

### 撤回 #9217 PR，公开承认抄袭行为，遵守 AGPL-3.0 协议要求，添加版权声明Alist 团队需公开透明的治理机制，解释收购细节和商业化计划，停止删除社区批评言论

**开源社区是无数开发者智慧与协作的结晶，其核心在于透明、尊重与共享。不够科技对 Alist 的“不够道德”管理，不仅伤害了 OpenList 团队，也背叛了整个开源社区的信任。我们呼吁所有关注开源生态的开发者、用户和技术爱好者，共同抵制 Alist 和不够科技的恶劣行为，唯有团结一致，才能守护开源社区的纯粹与未来。**