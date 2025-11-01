---
title: 使用国内源加速 npm 安装
date: 2025-10-31 18:00:00 +0800
categories: [网站建设]
tags: [Node.js, npm, 镜像源, 教程]
---


## 国内常用的 npm 镜像源


| 镜像源 | 地址 | 特点 |
|--------|------|------|
| **淘宝 npm 镜像** | `https://registry.npmmirror.com` | 阿里云提供，速度快，稳定性高 |
| **腾讯云 npm 镜像** | `https://mirrors.cloud.tencent.com/npm/` | 腾讯云提供，全国多节点 |
| **华为云 npm 镜像** | `https://mirrors.huaweicloud.com/repository/npm/` | 华为云提供，企业级稳定性 |
| **清华大学 TUNA** | `https://mirrors.tuna.tsinghua.edu.cn/npm/` | 教育网友好，科研机构常用 |

> **注意**：淘宝 npm 镜像的域名已从旧的 `registry.npm.taobao.org` 更新为 `registry.npmmirror.com`，请使用新域名。

## 临时使用镜像源

如果只是临时需要使用镜像源，可以在安装命令后添加 `--registry` 参数：

```bash
npm install --registry=https://registry.npmmirror.com
```

这种方式不会改变全局配置，只对当前这一次安装生效。适合偶尔需要使用的场景。

## 永久配置镜像源

### 方法一：使用 npm config 命令（推荐）

这是最简单直接的方法，一条命令搞定：

```bash
npm config set registry https://registry.npmmirror.com
```

执行后，npm 会将这个配置写入到用户配置文件 `~/.npmrc` 中。以后所有的 `npm install` 操作都会使用这个镜像源。

### 方法二：直接编辑配置文件

你也可以手动编辑 npm 的配置文件。打开或创建 `~/.npmrc` 文件（Windows 下位于 `C:\Users\你的用户名\.npmrc`），添加以下内容：

```
registry=https://registry.npmmirror.com
```

保存即可生效。

### 验证配置

配置完成后，可以用以下命令验证：

```bash
npm config get registry
```

如果输出的是你配置的镜像源地址，说明配置成功。

## 使用 nrm 管理镜像源

如果你需要在多个镜像源之间频繁切换（比如有时用淘宝源，有时用腾讯云源），可以使用 `nrm`（npm registry manager）这个工具。

### 安装 nrm

```bash
npm install -g nrm
```

### 查看可用的镜像源

```bash
nrm ls
```

输出类似：

```
* npm ---------- https://registry.npmjs.org/
  yarn --------- https://registry.yarnpkg.com/
  tencent ------ https://mirrors.cloud.tencent.com/npm/
  cnpm --------- https://r.cnpmjs.org/
  taobao ------- https://registry.npmmirror.com/
  npmMirror ---- https://skimdb.npmjs.com/registry/
```

前面带 `*` 的是当前正在使用的源。

### 切换镜像源

切换到淘宝源：

```bash
nrm use taobao
```

切换到腾讯云源：

```bash
nrm use tencent
```

### 添加自定义镜像源

如果你想添加其他镜像源：

```bash
nrm add <源名称> <源地址>
```

例如添加华为云镜像源：

```bash
nrm add huawei https://mirrors.huaweicloud.com/repository/npm/
```

### 测试镜像源速度

想知道哪个镜像源在你的网络环境下最快？用这个命令：

```bash
nrm test
```

它会测试所有镜像源的响应速度，并给出结果。

## 针对特定包使用不同的源

有些情况下，某些包可能只在特定的源上有，或者你希望某些包从官方源下载。这时可以使用 `scope` 配置：

```bash
npm config set @mycompany:registry https://npm.mycompany.com
```

这样，所有 `@mycompany/xxx` 格式的包都会从 `https://npm.mycompany.com` 下载，而其他包仍然使用默认的镜像源。

## yarn 用户的配置方法

如果你使用的是 yarn 而不是 npm，配置方法类似：

```bash
yarn config set registry https://registry.npmmirror.com
```

验证配置：

```bash
yarn config get registry
```

## pnpm 用户的配置方法

使用 pnpm 的话：

```bash
pnpm config set registry https://registry.npmmirror.com
```

验证配置：

```bash
pnpm config get registry
```

## 恢复为官方源

如果需要切换回官方源，只需执行：

```bash
npm config set registry https://registry.npmjs.org
```

或者使用 nrm：

```bash
nrm use npm
```

## 常见问题

### 配置了镜像源但还是很慢？

1. **清除缓存**：有时候 npm 缓存可能导致问题，尝试清除：
   ```bash
   npm cache clean --force
   ```

2. **检查网络**：确认你的网络连接正常，可以尝试 ping 镜像源地址

3. **更换镜像源**：不同地区的网络环境不同，试试其他镜像源

### 某个包安装失败？

国内镜像源虽然同步频繁，但可能存在几分钟的延迟。如果刚发布的新版本安装失败，可以：

1. 等待几分钟后重试
2. 临时切换回官方源安装这个包
3. 使用 `--registry` 参数指定官方源：
   ```bash
   npm install <package> --registry=https://registry.npmjs.org
   ```

### npm login 登录不了？

如果你需要发布包或使用私有包，需要登录 npm 账号。登录时必须使用官方源：

```bash
npm config set registry https://registry.npmjs.org
npm login
```

登录成功后，可以再切换回镜像源。
