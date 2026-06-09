# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## 项目概述

本项目目标是在 M 芯片 Mac 电脑，使用 Docker Ubuntu 22.02 和 VSCode 搭建 WebRTC 构建环境，掌握 WebRTC 技术。使用 Dev Container 作为 Docker 容器作为功能完整的开发环境。clangd 为 C/C++ 代码提供代码跳转功能。

## 目录结构

```tree
.
├── Dockerfile              # 镜像定义（Ubuntu 22.04 + 编译工具链）
├── .devcontainer/          # VS Code Dev Container 配置
│   └── devcontainer.json   # 引用 webrtc-docker:0.0.15 镜像，挂载 workspace
├── scripts/
│   └── docker-scripts.md   # Docker 镜像/容器的常用管理命令速查
└── webrtc-workspace/       # 运行时挂载目录（gitignore 忽略）
    ├── depot_tools/        # Chromium depot_tools 工具集
    └── webrtc-source/     # WebRTC 源码
```

## 架构要点

- **DEPOT_TOOLS** 环境变量指向 `/workspace/webrtc/depot_tools`，并已添加到 PATH，容器启动后可直接使用 `fetch`、`gclient`、`gn`、`ninja` 等 Chromium 构建工具。
- **clangd** 通过 apt 安装，VS Code 使用 clangd 作为 C++ 语言服务器，compile_commands.json 路径配置在 `.vscode/settings.json` 中（指向 `webrtc-workspace/webrtc-source/src/out/linux/$ARCH`）。
- **Apple Silicon Mac (M1/M2/M3)** 上构建镜像或运行容器时，建议指定 `--platform=linux/amd64`。虽然 Chromium/WebRTC 工具链已支持 ARM64 Linux 主机，但 depot_tools 中部分预编译二进制以及交叉编译工具链（Android NDK 等）在 x86_64 环境下兼容性更好、验证更充分。
- **远程调试**：需要 `--cap-add=SYS_PTRACE` 和 `--security-opt seccomp=unconfined` 开启 ptrace 能力，端口 5050 用于 gdbserver。
