# rtp_video_frame_h265_assembler_unittests

## 概述

H265 格式的 `RtpVideoFrameAssembler` 单元测试，验证 H265 RTP 包的解包和帧组装流程。测试覆盖 H265 NAL 单元解析、分片包（Fragmentation Unit, FU）的合并、单包模式的 Assembly、以及 depacketizer 对 H265 比特流的正确性处理。仅在 `RTC_ENABLE_H265` 编译标志启用时生效。
