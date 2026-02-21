---
title: "PyManager：Windows 上安装 Python 的新方式"
date: 2026-01-30 10:12:00 +0800
categories: [技术, Python]
tags: [Python, Windows, 安装]
description: 介绍在 Windows 上使用 PyManager 安装 Python 的方法
---
## 前言

如果你在 Windows 上安装/升级过 Python，你大概率经历过这些痛苦：

- 从 python.org 下载安装包，忘了勾选 `Add Python to PATH`？
- 安装完发现 `python` 命令不能用？
- 想装多个版本？PATH 冲突！
- 从 Microsoft Store 装的 Python 启动奇慢，还有各种莫名其妙的权限问题？
- 升级 Python 版本？只能重新下载安装包，不能自动更新！

Python 在 Windows 上推出全新的安装方式——**PyManager**（Python Install Manager）。传统的 `.exe` 安装包将在 Python 3.16 后被废弃，取而代之的是一个更现代、更智能的安装管理器。


---

## 为什么需要 PyManager？

### 现有安装方式的问题

在 PyManager 之前，Windows 用户安装 Python 主要使用安装包，但是升级或者装多个版本的时候：
```powershell
# 你以为你在用 3.13，实际上可能是 3.11
python --version
# Python 3.11.5  (什么？我明明装的是 3.13 啊！)
# Path 顺序问题？！
```

### PyManager 的解决方案

PyManager 是：**一个管理器管理所有版本**。

就像 Node.js 有 `nvm`，Rust 有 `rustup`，Ruby 有 `rbenv` 一样，还有 Flutter 和 `fvm`，Python 有了官方的版本管理工具。

安装 PyManager 后：
- `py` 命令用于管理和切换版本
- 多版本共存极其简单
- 安装、更新、卸载一条命令搞定

---

## 如何获取 PyManager

### 方式一：从 Microsoft Store 安装

最简单的方式。在 Windows 系统上，直接在终端输入：

```powershell
python
```
或
```powershell
python3
```

系统会自动打开 Microsoft Store，引导你安装 PyManager（以前是直接安装某个 Python 版本）

~~为什么 Windows 内置一个占位的 Python 启动器引导你去 Microsoft Store 安装，但是不内置别的语言？~~。

### 方式二：从 python.org 下载

访问 [python.org](https://www.python.org/downloads/)，下载 PyManager 的 MSIX 安装包，双击安装即可。

### 方式三：命令行安装

```powershell
# 使用 winget
winget install Python.PyManager
```

> **提示**：安装完成后，PyManager 会自动注册 `python`、`python3`、`py`、`pymanager` 这四个命令。

---

## PyManager 基本使用

### 查看帮助

```powershell
py help
```

这是需要记住的第一个命令。忘了怎么用？`py help` 救你。

### 安装 Python 版本

```powershell
# 安装最新稳定版
py install 3

# 安装特定版本
py install 3.12

# 安装精确版本
py install 3.12.5

# 安装最新版本（包括预发布版）
py install 3.14
```

与传统安装包不同，PyManager 从官方索引下载 Python，速度更快，也更可靠。

### 查看已安装的版本

```powershell
# 列出所有已安装的版本
py list

# 示例输出：
# PythonCore\3.13.1    C:\Users\你的用户名\AppData\Local\Python\PythonCore\3.13.1
# PythonCore\3.12.5    C:\Users\你的用户名\AppData\Local\Python\PythonCore\3.12.5
```

### 运行特定版本

```powershell
# 使用默认版本运行
python script.py

# 指定版本运行
py -V:3.12 script.py

# 简写形式
py -3.12 script.py
```

### 更新 Python

```powershell
# 更新所有已安装的版本
py install --upgrade

# 更新特定版本
py install --upgrade 3.13
```

### 卸载 Python 版本

```powershell
# 卸载特定版本
py uninstall 3.12

# 清空所有版本和缓存
py uninstall --purge
```

---

## 示例

### 需要特定版本？

某些软件（尤其是 GitHub 上 AI 相关的）和一些题目可能指定 Python 版本：

```powershell
# 安装指定版本
py install 3.8

# 使用指定版本运行
py -3.8 solution.py
```

### 配合虚拟环境使用？

PyManager 与 venv 完美兼容：

```powershell
# 使用特定版本创建虚拟环境
py -V:3.12 -m venv .venv

# 激活虚拟环境
.\.venv\Scripts\Activate

# 激活后，python 命令自动指向虚拟环境
python --version  # 3.12.x
```

激活虚拟环境后，`python` 命令会自动指向虚拟环境中的 Python，而不是 PyManager 的版本选择逻辑。这和以前的行为完全一致。


### 离线环境？

你可以提前下载好：

```powershell
# 在有网络的电脑上下载安装包
py install --download D:\python_packages 3.12

# 在离线电脑上安装
py install --source D:\python_packages\index.json 3.12
```

---

## 其他用法

### 查看可用版本

想知道有哪些版本可以安装？

```powershell
# 查看在线索引中的所有版本
py list --online
```

### 安装带调试符号的版本

如果你需要调试 Python 解释器本身（比如分析 C 扩展的问题），可以安装 PythonTest 版本（但是一般人都不需要吧）：

```powershell
# 安装带测试套件和调试符号的版本
py install PythonTest\3.13

# 使用这个版本
py -V:PythonTest\3.13 script.py
```

### 配置默认版本

如果你希望 `python` 命令默认使用某个版本，可以通过配置文件设置：

配置文件位置：`%AppData%\Python\PyManager.json`

```json
{
    "default": "3.12"
}
```

### 提取便携版（类似嵌入式包）

如果你需要一个不注册的、便携式的 Python（比如打包进你的程序）：

```powershell
py install --target D:\my_embedded_python 3.12
```

这会把 Python 解释器提取到指定目录，不会创建任何快捷方式或注册表项。

---

## 常见问题

### 已经装了传统安装包，会冲突吗？

PyManager 不会覆盖已有的 Python 安装。如果你想完全迁移到 PyManager，建议先卸载旧版本。

### Q: `py` 命令和以前的 `py.exe` 启动器有什么区别？

PyManager 的 `py` 命令兼容旧的 `py.exe` 启动器的所有功能，同时增加了 `install`、`uninstall`、`list` 等管理子命令。

### Q: 安装的 Python 在哪里？

默认安装路径：`%LocalAppData%\Python\PythonCore\<版本号>\`

例如：`C:\Users\你的用户名\AppData\Local\Python\PythonCore\3.13.1\`


### Q: pip 怎么用？

和以前一样：

```powershell
# 使用默认版本的 pip
python -m pip install numpy

# 指定版本
py -3.12 -m pip install numpy
```

注意：PyManager 不再提供全局的 `pip` 命令。可能要使用 `python -m pip` 的方式。

---

## 与其他工具的对比

你可能听说过 pyenv、conda、uv 这些工具，它们和 PyManager 有什么区别？
- **pyenv**：主要面向 Unix 系统而不是 Windows。PyManager 是官方工具，集成度更高。
- **conda**：更侧重于数据科学。但体积较大。PyManager 更轻量，专注于 Python 版本管理。
- **uv**：一个第三方的 Python 包管理器，主要管理环境和包。

---

## 迁移指南

如果你之前用的是传统安装包，这里是迁移步骤：

1. **卸载旧版本**（可选但推荐）
   - 打开"设置 → 应用 → 已安装的应用"
   - 找到所有 Python 版本并卸载
   - 找到 `Python Launcher` 并卸载

2. **安装 PyManager**
   - 从 python.org 下载并安装

3. **安装需要的 Python 版本**
   ```powershell
   py install 3.12
   py install 3.13
   ```

4. **验证**
   ```powershell
   python --version
   py list
   ```

---

## 时间线

根据 PEP 773 的计划：

- **2025 年 4 月**：PEP 773 正式通过
- **Python 3.14**：PyManager 开始在 Windows Store 发布
- **Python 3.16**（约 2027 年）：传统 `.exe` 安装包停止发布

也就是说，还有大约 1 年的缓冲期。


## 总结

PyManager 让你可以：
- 轻松安装和切换不同版本的 Python
- 与虚拟环境无缝配合
- 告别 PATH 冲突的

现在就试试吧！

---

## 参考资料

- [PEP 773](https://peps.python.org/pep-0773/)
- [Python Documentation](https://docs.python.org/3/using/windows.html)
