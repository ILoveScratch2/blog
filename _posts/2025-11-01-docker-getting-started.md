---
title: "Docker 入门指南"
date: 2025-11-01 21:55:01 +0800
categories: [技术, Docker]
tags: [Docker, 容器化, 教程]
description: 介绍 Docker 的基础概念
---

## Docker 是什么？

简单来说，Docker 是一个开源的容器化平台。它让你可以把应用程序及其依赖打包成一个轻量级、可移植的**容器（Container）**，然后在任何支持 Docker 的系统上运行。

### Docker vs 虚拟机

很多人会把 Docker 和虚拟机（VM）混淆 ~~之前也包括我~~ ......


| 特性 | Docker 容器 | 虚拟机 |
|------|------------|--------|
| 启动速度 | 秒级 | 分钟级 |
| 资源占用 | 轻量（MB级别） | 重量（GB级别） |
| 隔离性 | 进程级隔离 | 操作系统级隔离 |
| 性能 | 接近原生 | 有性能损耗 |

**虚拟机**：在物理机上运行完整的操作系统，每个 VM 都有独立的内核。就像在你的电脑上又装了几台完整的电脑。

**Docker 容器**：共享宿主机的内核，只包含应用和必要的依赖库。就像把应用装在一个个独立的"集装箱"里，轻便又高效。

### Docker 的核心概念

在深入学习之前，先理解这三个概念：

- **镜像（Image）**：可以理解为"模板"或"类"。比如一个包含了 Node.js 环境的镜像，就像一个预装了 Node.js 的虚拟光盘。
- **容器（Container）**：镜像的运行实例，相当于"对象"。从同一个镜像可以创建多个容器，它们互不干扰。
- **仓库（Registry）**：存放镜像的地方。最常用的是 Docker Hub，就像 GitHub 之于代码。(GitHub也有GHCR可以存放Docker镜像)

用个类比来说：镜像就是菜谱，容器就是按菜谱做出来的菜，仓库就是存放菜谱的图书馆。

## 安装 Docker

### Windows 安装

Windows 10/11 用户推荐使用 **Docker Desktop**：

1. **检查系统要求**：
   - Windows 10 64位：专业版、企业版或教育版（版本 1903 或更高）
   - 或 Windows 11 64位
   - 需要启用 WSL 2（Windows Subsystem for Linux）

2. **启用 WSL 2**：
   以管理员身份打开 PowerShell，执行：
   
   ```powershell
   wsl --install
   ```

   安装完成后重启电脑。

3. **下载安装 Docker Desktop**：
   访问 [Docker Desktop 官网](https://www.docker.com/products/docker-desktop/)，下载 Windows 版本。

4. **运行安装程序**：
   双击安装包，按提示操作。安装过程中会要求使用 WSL 2 作为后端，选择"是"。

5. **验证安装**：
   安装完成后，打开 PowerShell 或 CMD，输入：

   ```bash
   docker --version
   ```

   如果看到类似 `Docker version 24.0.6, build ed223bc` 的输出，说明安装成功！

   再试试运行一个测试容器：

   ```bash
   docker run hello-world
   ```

   如果能看到 "Hello from Docker!" 的欢迎信息，恭喜你，Docker 已经可以正常工作了。

> **提示**：如果遇到"WSL 2 installation is incomplete"错误，可能需要手动更新 WSL 2 Linux 内核。访问 [Microsoft 官方文档](https://aka.ms/wsl2kernel) 下载更新包。

### macOS 安装

macOS 用户同样使用 Docker Desktop：

1. **检查系统要求**：
   - macOS 11 Big Sur 或更新版本
   - Apple Silicon（M1/M2）或 Intel 芯片

2. **下载安装**：
   访问 [Docker Desktop 官网](https://www.docker.com/products/docker-desktop/)，根据你的芯片类型（Intel 或 Apple Silicon）下载对应版本。

3. **安装并运行**：
   - 打开下载的 `.dmg` 文件
   - 将 Docker 图标拖到"应用程序"文件夹
   - 从"启动台"或"应用程序"打开 Docker

4. **验证安装**：
   打开终端，执行：

   ```bash
   docker --version
   docker run hello-world
   ```

### Linux 安装

Linux 用户可以直接安装 Docker Engine，这里以 Ubuntu 为例：

1. **卸载旧版本**（如果有）：

   ```bash
   sudo apt-get remove docker docker-engine docker.io containerd runc
   ```

2. **更新软件包索引**：

   ```bash
   sudo apt-get update
   ```

3. **安装依赖**：

   ```bash
   sudo apt-get install \
       ca-certificates \
       curl \
       gnupg \
       lsb-release
   ```

4. **添加 Docker 官方 GPG 密钥**：

   ```bash
   sudo mkdir -p /etc/apt/keyrings
   curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
   ```

5. **设置仓库**：

   ```bash
   echo \
     "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
     $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
   ```

6. **安装 Docker Engine**：

   ```bash
   sudo apt-get update
   sudo apt-get install docker-ce docker-ce-cli containerd.io docker-compose-plugin
   ```

7. **验证安装**：

   ```bash
   sudo docker --version
   sudo docker run hello-world
   ```

8. **（可选）免 sudo 运行 Docker**：

   ```bash
   sudo usermod -aG docker $USER
   ```

   执行后需要注销并重新登录，之后就可以不加 `sudo` 直接运行 Docker 命令了。

## Docker 基础操作

安装完成后，我们来学习一些最常用的 Docker 操作。

### 获取镜像

从 Docker Hub 下载镜像非常简单，使用 `docker pull` 命令：

```bash
docker pull nginx
```

这会下载最新版本的 Nginx 镜像。如果想要指定版本：

```bash
docker pull nginx:1.24
```

查看本地已有的镜像：

```bash
docker images
```

输出类似这样：

```
REPOSITORY   TAG       IMAGE ID       CREATED        SIZE
nginx        latest    605c77e624dd   2 weeks ago    141MB
nginx        1.24      a6bd71f48f68   3 weeks ago    141MB
```

### 运行容器

有了镜像，就可以创建容器了。最简单的方式：

```bash
docker run nginx
```

但这样运行的容器会占据终端。更常用的是后台运行（`-d` 参数表示 detach）：

```bash
docker run -d nginx
```

执行后会返回一个长长的容器 ID，比如 `3f5a7b9c8e1d...`。

查看正在运行的容器：

```bash
docker ps
```

查看所有容器（包括已停止的）：

```bash
docker ps -a
```

### 端口映射

直接运行 Nginx 容器，你是无法从浏览器访问的，因为容器内部的端口没有映射到宿主机。使用 `-p` 参数进行端口映射：

```bash
docker run -d -p 8080:80 nginx
```

这表示把容器的 80 端口映射到宿主机的 8080 端口。现在打开浏览器访问 `http://localhost:8080`，就能看到 Nginx 的欢迎页面了！

### 命名容器

默认情况下，Docker 会给容器分配一个随机名字（比如 `funny_tesla`）。使用 `--name` 参数可以指定一个有意义的名字：

```bash
docker run -d -p 8080:80 --name my-nginx nginx
```

之后的操作就可以用这个名字代替容器 ID 了。

### 停止和删除容器

停止容器：

```bash
docker stop my-nginx
```

启动已停止的容器：

```bash
docker start my-nginx
```

重启容器：

```bash
docker restart my-nginx
```

删除容器（需要先停止）：

```bash
docker stop my-nginx
docker rm my-nginx
```

强制删除正在运行的容器：

```bash
docker rm -f my-nginx
```

### 进入容器

有时候需要进入容器内部进行调试，使用 `docker exec` 命令：

```bash
docker exec -it my-nginx bash
```

- `-i`：保持 STDIN 打开
- `-t`：分配一个伪终端
- `bash`：要执行的命令

这样就进入了容器的 Bash 终端，可以像操作 Linux 服务器一样操作容器了。输入 `exit` 退出。

### 查看日志

查看容器的输出日志：

```bash
docker logs my-nginx
```

实时查看日志（类似 `tail -f`）：

```bash
docker logs -f my-nginx
```

## 实战：容器化一个 Node.js 应用

理论讲得再多，不如动手实践。下面我们从零开始，把一个简单的 Node.js 应用容器化。

### 创建示例应用

首先创建一个简单的 Express 应用：

```bash
mkdir my-node-app
cd my-node-app
npm init -y
npm install express
```

创建 `app.js` 文件：

```javascript
const express = require('express');
const app = express();
const PORT = 3000;

app.get('/', (req, res) => {
  res.json({
    message: 'Hello from Docker!',
    timestamp: new Date().toISOString()
  });
});

app.listen(PORT, () => {
  console.log(`Server is running on port ${PORT}`);
});
```

本地测试一下：

```bash
node app.js
```

访问 `http://localhost:3000`，能看到 JSON 响应就说明应用正常。

### 编写 Dockerfile

Dockerfile 是构建 Docker 镜像的"配方"。在项目根目录创建一个名为 `Dockerfile` 的文件（注意没有扩展名）：

```dockerfile
# 使用官方 Node.js 镜像作为基础镜像
FROM node:18-alpine

# 设置工作目录
WORKDIR /app

# 复制 package.json 和 package-lock.json
COPY package*.json ./

# 安装依赖
RUN npm install --production

# 复制应用代码
COPY . .

# 暴露端口
EXPOSE 3000

# 启动应用
CMD ["node", "app.js"]
```

逐行解释一下：

- `FROM`：指定基础镜像。`node:18-alpine` 是一个轻量级的 Node.js 18 镜像（基于 Alpine Linux）。
- `WORKDIR`：设置容器内的工作目录，后续的命令都在这个目录下执行。
- `COPY package*.json ./`：先复制依赖文件，利用 Docker 的缓存机制提高构建速度。
- `RUN npm install`：安装依赖。`--production` 参数表示只安装生产环境依赖。
- `COPY . .`：复制所有应用代码到容器。
- `EXPOSE 3000`：声明容器监听的端口（仅作说明，不会实际映射端口）。
- `CMD`：指定容器启动时执行的命令。

### 创建 .dockerignore

类似 `.gitignore`，`.dockerignore` 用于排除不需要打包进镜像的文件：

```
node_modules
npm-debug.log
.git
.gitignore
README.md
.env
```

### 构建镜像

在项目目录下执行：

```bash
docker build -t my-node-app .
```

- `-t my-node-app`：给镜像打标签（命名）
- `.`：Dockerfile 所在的目录（当前目录）

构建过程会输出每一步的执行情况。完成后，查看镜像：

```bash
docker images
```

应该能看到刚创建的 `my-node-app` 镜像。

### 运行容器

```bash
docker run -d -p 3000:3000 --name my-app my-node-app
```

访问 `http://localhost:3000`，如果能看到 JSON 响应，说明容器化成功！

查看运行日志：

```bash
docker logs my-app
```

应该能看到 "Server is running on port 3000" 的输出。

## Docker Compose：管理多容器应用

实际项目中，应用往往不是孤立的。比如一个 Web 应用可能需要：

- Node.js 应用服务器
- MySQL 数据库
- Redis 缓存
- Nginx 反向代理

手动管理这么多容器会很麻烦，**Docker Compose** 就是为此而生的。它让你用一个 YAML 文件定义整个应用栈，一键启动所有服务。

### 安装 Docker Compose

- **Windows/macOS**：Docker Desktop 已经内置了 Docker Compose，无需额外安装。
- **Linux**：Docker Compose 已经作为 Docker Engine 的插件集成，如果按照前面的步骤安装了 `docker-compose-plugin`，应该已经可用了。

验证安装：

```bash
docker compose version
```

### 示例：Node.js + MongoDB 应用

创建一个 `docker-compose.yml` 文件：

```yaml
version: '3.8'

services:
  app:
    build: .
    ports:
      - "3000:3000"
    environment:
      - MONGO_URL=mongodb://mongo:27017/myapp
    depends_on:
      - mongo
    networks:
      - app-network

  mongo:
    image: mongo:6
    volumes:
      - mongo-data:/data/db
    networks:
      - app-network

volumes:
  mongo-data:

networks:
  app-network:
```

关键配置说明：

- `services`：定义了两个服务，`app`（Node.js 应用）和 `mongo`（MongoDB）。
- `build: .`：从当前目录的 Dockerfile 构建镜像。
- `depends_on`：声明依赖关系，确保 MongoDB 先启动。
- `volumes`：持久化数据，即使容器删除，数据库数据也不会丢失。
- `networks`：创建一个自定义网络，让容器之间可以通过服务名互相访问。

启动整个应用栈：

```bash
docker compose up -d
```

查看运行状态：

```bash
docker compose ps
```

查看日志：

```bash
docker compose logs -f
```

停止并删除所有容器：

```bash
docker compose down
```

如果还想删除数据卷（会丢失数据库数据）：

```bash
docker compose down -v
```

## 一些实用技巧

### 清理无用资源

Docker 使用久了会产生很多"垃圾"：停止的容器、无用的镜像、悬空的数据卷等。一键清理：

```bash
docker system prune
```

如果还想删除所有未使用的镜像（不仅仅是悬空镜像）：

```bash
docker system prune -a
```

### 查看容器资源占用

实时查看容器的 CPU、内存、网络等资源使用情况：

```bash
docker stats
```

### 限制容器资源

防止某个容器占用过多资源：

```bash
docker run -d --name my-app \
  --memory="512m" \
  --cpus="1.0" \
  my-node-app
```

这会限制容器最多使用 512MB 内存和 1 个 CPU 核心。

### 使用国内镜像加速

Docker Hub 在国内访问速度可能较慢，可以配置镜像加速器。以阿里云为例：

1. 注册阿里云账号，访问[容器镜像服务](https://cr.console.aliyun.com/)
2. 在"镜像加速器"页面获取专属加速地址
3. 配置 Docker：
   - **Docker Desktop（Windows/macOS）**：设置 → Docker Engine → 编辑 JSON 配置，添加：
     ```json
     {
       "registry-mirrors": ["https://你的加速地址.mirror.aliyuncs.com"]
     }
     ```
   - **Linux**：编辑 `/etc/docker/daemon.json`（没有就创建）：
     ```json
     {
       "registry-mirrors": ["https://你的加速地址.mirror.aliyuncs.com"]
     }
     ```
     然后重启 Docker：
     ```bash
     sudo systemctl daemon-reload
     sudo systemctl restart docker
     ```

### 多阶段构建优化镜像大小

对于需要编译的项目（如 Go、Rust、前端项目），可以使用多阶段构建减小最终镜像体积：

```dockerfile
# 构建阶段
FROM node:18 AS builder
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
RUN npm run build

# 运行阶段
FROM node:18-alpine
WORKDIR /app
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/node_modules ./node_modules
EXPOSE 3000
CMD ["node", "dist/app.js"]
```

第一阶段包含所有构建工具（体积大），第二阶段只复制构建产物（体积小），最终镜像只包含第二阶段。

## 常见问题与解决

### 问题 1：容器无法访问宿主机的服务

**症状**：容器内的应用需要连接宿主机上运行的数据库，但连接失败。

**解决**：使用特殊的主机名：
- **Windows/macOS**：使用 `host.docker.internal`
- **Linux**：使用 `--network host` 或手动指定宿主机 IP

例如，连接宿主机的 MySQL：

```javascript
const connection = mysql.createConnection({
  host: 'host.docker.internal',  // 代替 'localhost'
  user: 'root',
  password: 'password',
  database: 'mydb'
});
```

### 问题 2：端口已被占用

**症状**：运行 `docker run -p 8080:80` 时报错 "port is already allocated"。

**解决**：
1. 查看是哪个进程占用了端口：
   - Windows: `netstat -ano | findstr :8080`
   - macOS/Linux: `lsof -i :8080`
2. 终止占用端口的进程，或换一个端口映射，比如 `-p 8081:80`

### 问题 3：镜像构建时网络超时

**症状**：`npm install` 或 `apt-get` 等命令经常超时。

**解决**：
1. 使用国内镜像源（npm、apt 等都有对应的国内镜像）
2. 配置 Docker 镜像加速器（见上文）
3. 在 Dockerfile 中设置镜像源，比如 npm：
   ```dockerfile
   RUN npm config set registry https://registry.npmmirror.com
   RUN npm install
   ```