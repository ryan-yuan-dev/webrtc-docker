# WebRTC 编译环境镜像
# 目标平台：iOS / Android / Windows / macOS / Linux / OpenHarmony OS (OHOS)
#
# 镜像不包含 WebRTC 源码，运行时通过 volume 挂载 webrtc-workspace 目录到 /workspace/webrtc。
# Apple Silicon Mac (M1/M2/M3) 构建时需指定 --platform=linux/amd64：
#   docker build --platform=linux/amd64 -t webrtc-docker:latest .
#
# depot_tools 中部分预编译二进制（如 gn）在 ARM64 Linux 上兼容性不如 x86_64，
# 且交叉编译工具链（Android NDK 等）在 x86_64 主机上验证更充分，因此固定为 linux/amd64。

FROM --platform=linux/amd64 ubuntu:22.04

LABEL maintainer="Ryan"
LABEL description="WebRTC build environment based on Ubuntu 22.04"

# 避免 apt-get 安装过程中的交互式提示
ENV DEBIAN_FRONTEND=noninteractive

# Docker 官方提供的 ubuntu 基础镜像十分精简，默认不包含 CA 证书包，所以 sources.list 中使用 http 源。
# 优先使用国内镜像，加速 apt-get 安装速度。先安装 `ca-certificates` 包以支持 HTTPS 源，再替换 sources.list 为 https 源。
RUN rm -f /etc/apt/sources.list
COPY webrtc-workspace/sources.list /etc/apt/sources.list

# ============================================================
# 2. 语言环境 + 基础工具链
# ============================================================
# locales：WebRTC 构建脚本对 locale 敏感，未设置 UTF-8 会导致 gn/ninja 报编码错误
# python3：depot_tools（fetch/gclient/gn）的运行时依赖
# lsb-release：depot_tools 用于识别 Ubuntu 版本以选择正确的预编译二进制
# ninja-build：WebRTC 默认构建后端
# clangd：C++ 语言服务器，供 VS Code / Dev Container 使用
# vim / curl / wget / git：日常开发与源码管理
#
# 注意：apt-get update 和 apt-get install 必须在同一个 RUN 中，
# 否则 Docker 层缓存会导致包索引与安装脱节，出现 Unable to locate package 错误。
RUN apt-get update && apt-get install -y --no-install-recommends \
  sudo \
  ca-certificates \
  openjdk-17-jdk \
  locales \
  python3 \
  python3-pip \
  python3-setuptools \
  lsb-release \
  pkg-config \
  file \
  xz-utils \
  zip \
  unzip \
  iputils-ping \
  vim \
  curl \
  wget \
  git \
  && localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8 \
  && rm -rf /var/lib/apt/lists/*

# 升级 git 版本，Ubuntu 22.04 默认的 git 版本较旧，可能不兼容 WebRTC 的某些 git 功能（如 sparse checkout）。通过添加 PPA 来安装最新版本的 git
RUN add-apt-repository ppa:git-core/ppa && apt-get update && apt-get install -y git

ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8
ENV JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64/bin

# Docker 官方提供的基础镜像（如 ubuntu:latest）大都十分精简，默认不包含 CA 证书包，导致系统无法验证阿里云 HTTPS 源的 SSL 证书安全性，从而报错。
RUN sed -i 's|http://|https://|g' /etc/apt/sources.list

# ============================================================
# 3. depot_tools 环境变量
# ============================================================
# depot_tools 不在镜像中安装，而是由用户挂载到 webrtc-workspace/depot_tools。
# 此处仅预创建父目录并写入 bashrc，容器启动后即可直接使用 fetch / gclient / gn / ninja 等命令。
ENV DEPOT_TOOLS=/workspace/webrtc/depot_tools

# gclient sync 时不自动更新 depot_tools
ENV DEPOT_TOOLS_UPDATE=0
# 设置 CIPD HTTP 下载重试次数，提升网络不稳定时的成功率
ENV CIPD_HTTP_RETRIES=10
# CIPD 和 git 都支持本地缓存，能显著提升构建效率并减少网络依赖。预创建缓存目录，并通过环境变量告知 depot_tools 使用这些目录
ARG WEBRTC_GIT_CACHE=/workspace/webrtc/.webrtc-git-cache
ARG CIPD_CACHE=/workspace/webrtc/.cipd_cache
RUN mkdir -p ${WEBRTC_GIT_CACHE} && mkdir -p ${CIPD_CACHE}
# webrtc git 缓存目录
ENV GIT_CACHE_PATH="${WEBRTC_GIT_CACHE}"
# CIPD 缓存目录
ENV CIPD_CACHE_DIR="${CIPD_CACHE}"

# 将 depot_tools 加入环境变量，使用 gclient ninja 等命令
RUN mkdir -p "$(dirname "$DEPOT_TOOLS")" \
  && echo "export DEPOT_TOOLS=${DEPOT_TOOLS}" >> /etc/bash.bashrc \
  && echo "export PATH=${DEPOT_TOOLS}:\$PATH" >> /etc/bash.bashrc


# 默认工作目录（与 volume 挂载目标一致）
WORKDIR /workspace/webrtc
