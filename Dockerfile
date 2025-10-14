# 使用 ubuntu 20.04 作为基础镜像，支持多平台构建
FROM ubuntu:22.04

LABEL maintainer="Ryan"

# 避免交互式安装
ENV DEBIAN_FRONTEND=noninteractive

# 设置语言环境（UTF-8）
RUN apt-get update && apt-get install -y locales \
  && localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8 \
  && rm -rf /var/lib/apt/lists/*
ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

RUN apt-get update && apt-get install -y python3 python3-pip python3-setuptools \
  && rm -rf /var/lib/apt/lists/*

RUN pip3 install apt-select && apt-select --country CN \
  && cp /etc/apt/sources.list /etc/apt/sources.list.backup \
  && mv sources.list /etc/apt/

RUN echo $(cat /etc/apt/sources.list)

# 安装基础开发工具、Python、Java 等依赖
RUN apt-get update --fix-missing && apt-get install -y --no-install-recommends \
  vim curl wget git clangd \
  && rm -rf /var/lib/apt/lists/*

# 安装 depot_tools 并添加到 PATH
ENV DEPOT_TOOLS=/workspace/webrtc/depot_tools
RUN mkdir -p $(dirname $DEPOT_TOOLS) \
  && echo "export DEPOT_TOOLS=/workspace/webrtc/depot_tools" >> /etc/bash.bashrc \
  && echo "export PATH=$PATH:$DEPOT_TOOLS" >> /etc/bash.bashrc 

# 设置默认工作目录
WORKDIR /workspace/webrtc
