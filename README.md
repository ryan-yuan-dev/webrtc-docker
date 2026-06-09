# WebRTC 编译

本仓库通过 Dockerfile 记录完整的 WebRTC 源码编译流程，用于自动化构建 WebRTC 编译环境镜像，避免重复配置开发环境的困扰。

由于 WebRTC 源码及编译工具体积庞大，镜像本身不包含源码。使用时需将 WebRTC 源码放置于 `webrtc-workspace` 目录下，并挂载至容器中。

目标平台支持：iOS、Android、Windows、macOS、Linux、OpenHarmony OS (OHOS)。

WebRTC 源码托管在 googlesource.com，拉取代码时请确保 VPN 全局模式已开启，以保证网络访问正常。`Ubuntu` 中安装工具包，推荐设置[清华镜像](https://mirrors.tuna.tsinghua.edu.cn/help/ubuntu-ports/)，提升下载速度，避免访问失败。

## webrtc docker 镜像构建与运行

### 环境要求

- 确保系统已安装并运行 Docker 服务
- webrtc-workspace 目录中需包含 WebRTC 源代码
- webrtc-workspace/depot_tools 目录中需包含 depot_tools 工具集

### 镜像编译

1. 将 webrtc 源码放入 `webrtc-workspace` 目录下；
2. 将 depot_tools 源码放入 `webrtc-workspace/depot_tools` 目录下；
3. 构建镜像（Apple Silicon Mac 需指定 `--platform=linux/amd64`）；

   ```bash
   # 通用构建
   docker build -t webrtc-docker:latest .
   # Apple Silicon Mac (M1/M2/M3)
   docker build --platform=linux/amd64 -t webrtc-docker:latest .
   ```

### 创建运行容器

```bash
# 从 webrtc-docker 镜像创建容器，挂载 webrtc-workspace 目录到容器的 /workspace/webrtc，
# 容器启动后进入 bash 终端，工作目录为 /workspace/webrtc
docker run -it --name webrtc --network=host -v $(pwd)/webrtc-workspace:/workspace/webrtc webrtc-docker:latest /bin/bash

# 创建支持远程调试的容器，挂载 webrtc-android 源码目录到容器的 /workspace/webrtc。
# --cap-add=SYS_PTRACE 和 --security-opt seccomp=unconfined 开启 ptrace 调试能力。
# Apple Silicon Mac (M1/M2/M3) 需要 --platform=linux/amd64
docker run -it --name webrtc-remote-debug --network=host --platform=linux/amd64 --cap-add=SYS_PTRACE --security-opt seccomp=unconfined -p 5050:5050 -v $(pwd)/webrtc-workspace/webrtc-android:/workspace/webrtc webrtc-docker:latest /bin/bash
```

## WebRTC 源码编译

### Linux

1. 执行 `bash build/install-build-deps.sh` 安装构建工具。如果出现依赖库安装失败问题时，多尝试几次。
2. 运行 `gn gen out/Linux/x86_64 --args='target_os="linux" target_cpu="x64" is_clang=true use_sysroot=false'` 生成编译配置文件。
