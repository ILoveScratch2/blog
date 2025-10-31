---
title: 绕过Windows 11/10的联网强制要求
date: 2025-10-23 11:11:00 +0800
categories: [Windows]
tags: [GitHub, Windows, 教程, Dev, 软件]
math: true
description: 绕过Windows 11/10的联网强制要求
---

方法1：

针对 Windows 11 专业版、企业版，在安装的过程中，选择“为工作或学校设置”选项，进入后再选择里面的 “改为域加入”，就可以创建本地账户了


方法2：

1、提前断开WiFi 拔掉网线
2、在需要登录账户的OOBE屏幕，按 Shift+F10 打开命令提示符

3、在命令提示符中输入以下命令：
  ```
  reg add HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\OOBE /v BypassNRO /t REG_DWORD /d 1 /f
  ```

4、执行上述命令后，重启系统：
  ```
  shutdown /r /t 0
  ```
方法3：

1、在安装界面输入快捷键：Shift+F10，打开命令提示符

2、然后在命令提示符下输入以下命令，来创建本地用户

```
net user 用户名  /add                          
net localgroup Administrators 用户名 /add                                                          
cd OOBE
msoobe && shutdown -r
```