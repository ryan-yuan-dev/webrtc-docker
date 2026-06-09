# rtp_packet_info_unittest

## 概述

`rtp_packet_info_unittest.cc` 是对 `api/rtp_packet_info.h` 中 `RtpPacketInfo` 类的单元测试文件。

## 测试范围

- 默认构造
- 从指定参数构造（ssrc, csrcs, timestamp, receive_time）
- 从 `RTPHeader` 构造
- SSRC / CSRCs 的 setter/getter
- RTP 时间戳的设置和获取
- `receive_time` 的设置和获取
- `audio_level` 的设置和获取
- `absolute_capture_time` 的设置和获取
- `local_capture_clock_offset` 的设置和获取
- `operator==` / `operator!=` 比较
- 拷贝和移动语义
