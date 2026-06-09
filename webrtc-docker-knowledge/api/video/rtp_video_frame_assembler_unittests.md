# rtp_video_frame_assembler_unittests

## 概述

`RtpVideoFrameAssembler` 的单元测试，覆盖多种负载格式（VP8、VP9、H264、AV1、Generic、Raw）的 RTP 包组装过程。测试包括：单个包构成完整帧的处理、多个包分片帧的组装、乱序包到达的处理、padding 包的触发效果、依赖描述符（Dependency Descriptor）和通用帧描述符（Generic Frame Descriptor）扩展头的解析、H265 支持（`#ifdef RTC_ENABLE_H265`）。
