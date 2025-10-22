---
title: 为MuMu模拟器开启自由窗口
date: 2025-09-08 12:50:01 +0800
categories: [Android]
tags: [GitHub, Android, Flutter, Dev, 模拟器, MuMu, 教程]
math: true
image: assets/img/mumu.png
description: 为MuMu模拟器开启自由窗口
---


## 前言


MuMu模拟器是由网易推出的一款安卓模拟器，因其良好的性能和兼容性，受到了许多用户的喜爱。然而，默认情况下，MuMu模拟器的窗口大小是固定的，这对于一些需要自定义窗口大小的用户来说可能不太方便。就介绍如何为MuMu模拟器开启自由窗口功能。


## 1. 下载并安装MuMu模拟器

首先，下载并安装了最新版本的MuMu模拟器。从[MuMu官方网站](https://mumu.163.com/)下载最新版本的安装包，并按照提示完成安装。

当然，B站上也有很多教程，可以自行搜索。

B站上还有去广告ROOT版的，这里只要是MuMu 12都可以。


## 2. 启用ADB

为了能够更好地控制MuMu模拟器的窗口，我们需要启用ADB（Android Debug Bridge）功能。ADB是一个多功能命令行工具。
首先，需要安装ADB，可以下载[Android SDK Platform Tools](https://developer.android.com/studio/releases/platform-tools)。

启用ADB，按照以下步骤操作：

1. 打开MuMu模拟器，启动一个设备，点击右上角的“...”->“设备设置”。
2. 在“设备设置”中，找到“其他”，打开“本机ADB调试”。

![开启ADB](https://blog.ilovescratch.dpdns.org/assets/img/mumu-enable-adb.png)

默认情况下，本机ADB调试是选择的的，手动开启以防万一。

## 3. 连接ADB

打开命令行工具（如CMD、PowerShell或终端），导航到你安装ADB的目录，然后输入以下命令连接到MuMu模拟器：

```
adb connect 127.0.0.1:5555
```
（ 注：如果连接失败，请检查MuMu模拟器是否已启动，并确保ADB已正确安装。可以通过 [这篇教程](https://mumu.163.com/help/20230214/35047_1073151.html) 查看ADB端口，并替换:后面的数字 ）


## 4. 设置自由窗口

在连接成功后，使用以下命令：

```
adb shell settings put global force_resizable_activities 1
adb shell settings put global enable_freeform_support 1
adb reboot
```

这将启用MuMu模拟器的自由窗口功能。执行完命令后，重启模拟器以使设置生效。


## 5. 使用自由窗口

重启后，打开一个App，点击“多任务”，然后长按应用窗口上方的图标，“自由窗口”选项。

![自由窗口](https://blog.ilovescratch.dpdns.org/assets/img/mumu-freeform.png)

