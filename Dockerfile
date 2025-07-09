
FROM ubuntu:24.04

LABEL Author="Ryan"

RUN apt-get update && apt-get install -y locales && rm -rf /var/lib/apt/lists/* \
  && localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8

ENV LANG=en_US.utf8

# 存放 webrtc 源文件
WORKDIR /workspace/webrtc

# 存放编译环境
WORKDIR /environment