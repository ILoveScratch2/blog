---
title: "使用 NVM 管理 Node.js 版本"
date: 2025-10-31 12:00:00 +0800
categories: [技术, Node.js]
tags: [Node.js, NVM, 版本管理, 教程]
---

你有没有遇到过这样的情况:刚接手一个老项目,兴冲冲地 `npm install`,结果报错说 Node.js 版本不兼容;而你手头的另一个新项目偏偏又需要最新版本的 Node.js。在不同版本之间反复卸载重装?那可太折腾了。

好在我们有 NVM(Node Version Manager)这个神器。它就像是 Node.js 的"衣柜管理员",帮你把各个版本整整齐齐地收纳好,想用哪个随时切换,再也不用为版本冲突头疼了。

## NVM 到底是什么?

简单来说,NVM 就是一个专门用来管理 Node.js 版本的命令行工具。有了它,你可以:

- **同时安装多个版本**:Node.js 12、14、16、18...想装几个装几个,互不干扰
- **秒速切换版本**:一条命令就能在不同版本间自由穿梭
- **项目自动适配**:配合 `.nvmrc` 文件,每个项目都能自动使用对应的版本

特别是对于需要维护多个项目的开发者来说,NVM 简直是刚需。

## 安装 NVM

### Windows 用户看这里

Windows 上的安装相对简单,使用的是社区维护的 `nvm-windows` 项目:

1. **下载安装包**:前往 [nvm-windows](https://github.com/coreybutler/nvm-windows/releases) 的 GitHub 发布页,下载最新版的 `nvm-setup.exe`

2. **运行安装程序**:双击安装包,一路 Next 即可。安装过程中会自动配置环境变量,不需要手动操作

3. **验证安装**:安装完成后,打开 PowerShell 或命令提示符,输入:

   ```bash
   nvm version
   ```

   如果看到类似 `1.1.11` 这样的版本号,恭喜你,安装成功!

   > **小提示**:如果提示 `nvm` 命令未找到,可能需要重启终端或电脑让环境变量生效。

### macOS/Linux 用户看这里

macOS 和 Linux 上使用的是官方的 `nvm` 项目,通过脚本安装:

1. **运行安装脚本**:打开终端,复制粘贴下面的命令:

   ```bash
   curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.5/install.sh | bash
   ```

   这个脚本会自动下载 NVM 并配置环境变量。整个过程大概需要几秒钟。

2. **让配置生效**:安装完成后,需要重新加载 Shell 配置文件。如果你用的是 Bash:

   ```bash
   source ~/.bashrc
   ```

   如果是 Zsh(macOS 默认):

   ```bash
   source ~/.zshrc
   ```

   或者直接关闭终端重新打开也行。

3. **检查是否成功**:输入以下命令:

   ```bash
   nvm --version
   ```

   看到版本号就说明 OK 了!

   > **注意**:macOS 用户如果使用的是其他 Shell(如 Fish),可能需要额外的配置步骤,具体可以参考 [官方文档](https://github.com/nvm-sh/nvm#install--update-script)。

## 开始使用 NVM

安装好 NVM 后,我们就可以愉快地玩耍了。下面介绍几个最常用的操作。

### 安装 Node.js

想要安装某个版本的 Node.js,只需要:

```bash
nvm install <版本号>
```

比如你想安装 Node.js 18.17.1 这个长期支持版本(LTS):

```bash
nvm install 18.17.1
```

NVM 会自动从官方源下载并安装。安装完成后,这个版本就会自动被激活使用。

你也可以用一些快捷关键词:

```bash
nvm install node        # 安装最新版本
nvm install --lts       # 安装最新的 LTS 版本
nvm install 18          # 安装 18.x 的最新版本
```

### 切换 Node.js 版本

这是 NVM 最核心的功能。当你需要切换到某个版本时:

```bash
nvm use <版本号>
```

比如切换到刚才安装的 18.17.1:

```bash
nvm use 18.17.1
```

执行后,当前终端会话就会使用这个版本的 Node.js 和 npm 了。可以用 `node -v` 验证一下:

```bash
$ node -v
v18.17.1
```

需要注意的是,**`nvm use` 只对当前终端会话生效**。如果你打开了新的终端窗口,它会使用默认版本。想要设置全局默认版本,可以用:

```bash
nvm alias default 18.17.1
```

### 查看已安装的版本

时间久了,装的版本多了,可能会忘记都装了哪些。这时候用:

```bash
nvm list
```

它会列出所有已安装的版本,并用箭头标记当前正在使用的版本:

```
  * v18.17.1 (Currently using 64-bit executable)
    v16.20.0
    v14.21.3
```

在 macOS/Linux 上,`nvm list` 还会显示各个版本对应的别名。

### 卸载不需要的版本

Node.js 版本装多了也挺占空间的。不需要的版本可以卸载掉:

```bash
nvm uninstall <版本号>
```

例如:

```bash
nvm uninstall 14.21.3
```

注意,当前正在使用的版本是无法卸载的,需要先切换到其他版本。

## 项目级版本管理:`.nvmrc` 文件

这是一个特别实用的技巧。想象一下,你的团队有好几个人,每个人电脑上的 Node.js 版本都不一样,这很容易导致"在我电脑上能跑"的尴尬局面。

解决方案就是在项目根目录下创建一个 `.nvmrc` 文件,里面写上项目需要的 Node.js 版本:

```
18.17.1
```

就这么简单,一行字搞定。也可以使用 `lts/hydrogen` 这样的别名。

当团队成员克隆项目后,只需要在项目目录下运行:

```bash
nvm use
```

NVM 会自动读取 `.nvmrc` 文件,并切换到对应的版本。如果这个版本还没安装,NVM 会提示你先用 `nvm install` 安装。

这样做的好处是:

- **环境统一**:所有人用的 Node.js 版本都一样,避免因版本差异导致的 bug
- **新人友好**:新同事加入时不用问"这个项目用哪个版本的 Node.js"
- **自动化**:可以配合 Shell 的 hook 功能,在进入项目目录时自动切换版本

### 更进一步:自动切换版本

如果你觉得每次进入项目目录都要手动 `nvm use` 很麻烦,可以配置 Shell 自动切换。以 Zsh 为例,在 `~/.zshrc` 中添加:

```bash
autoload -U add-zsh-hook
load-nvmrc() {
  local node_version="$(nvm version)"
  local nvmrc_path="$(nvm_find_nvmrc)"

  if [ -n "$nvmrc_path" ]; then
    local nvmrc_node_version=$(nvm version "$(cat "${nvmrc_path}")")

    if [ "$nvmrc_node_version" = "N/A" ]; then
      nvm install
    elif [ "$nvmrc_node_version" != "$node_version" ]; then
      nvm use
    fi
  elif [ "$node_version" != "$(nvm version default)" ]; then
    echo "Reverting to nvm default version"
    nvm use default
  fi
}
add-zsh-hook chpwd load-nvmrc
load-nvmrc
```

这样一来,每次 `cd` 进入有 `.nvmrc` 的目录时,版本就会自动切换,体验超级丝滑。

## 一些实用技巧

### 查看可安装的版本列表

想知道 Node.js 有哪些版本可以安装?用这个命令:

```bash
nvm list available    # Windows
nvm ls-remote         # macOS/Linux
```

会列出所有可用的版本,包括 LTS 和最新版本。

### 使用最新的 LTS 版本

不确定该装哪个版本?装 LTS 版本准没错:

```bash
nvm install --lts
nvm use --lts
```

### 在特定版本下运行命令

有时候你不想切换全局版本,只是想用某个版本运行一次命令。可以这样:

```bash
nvm exec 16.20.0 node app.js
```

这会在 Node.js 16.20.0 环境下运行 `app.js`,但不会改变当前会话的版本。

## 写在最后

最后提醒一点:**NVM 和直接安装的 Node.js 会有冲突**。如果你之前直接安装过 Node.js,建议先卸载掉,再用 NVM 来管理。这样能避免很多奇怪的问题。