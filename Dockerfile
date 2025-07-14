
FROM ubuntu:24.04

LABEL Author="Ryan"

RUN apt-get update && apt-get install -y locales \
  && localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8

ENV LANG=en_US.utf8

# 设置环境变量，避免交互模式
ENV DEBIAN_FRONTEND=noninteractive

# 安装 vim
RUN apt-get install -y vim 

# 清理缓存以减小镜像体积
RUN rm -rf /var/lib/apt/lists/*

# 存放 webrtc 源文件5
WORKDIR /workspace/webrtc

# 存放编译环境
WORKDIR /environment