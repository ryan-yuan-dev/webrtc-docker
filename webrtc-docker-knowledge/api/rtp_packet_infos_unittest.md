# rtp_packet_infos_unittest

## 概述

`rtp_packet_infos_unittest.cc` 是对 `api/rtp_packet_infos.h` 中 `RtpPacketInfos` 类的单元测试文件。`RtpPacketInfos` 是 `RtpPacketInfo` 的集合类型。

## 测试范围

- 默认构造（空集合）
- 从 `vector<RtpPacketInfo>` 构造
- `size()` / `empty()` 集合大小
- `begin()` / `end()` 迭代器
- `operator[]` 按索引访问
- 从 `RtpPacketInfo` 列表添加元素
- 拷贝和移动语义
- `operator==` / `operator!=` 比较
