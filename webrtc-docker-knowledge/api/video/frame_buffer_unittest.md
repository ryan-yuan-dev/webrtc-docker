# frame_buffer_unittest

## 概述

`FrameBuffer` 的单元测试，覆盖帧缓冲区核心功能：帧插入、连续性和可解码性传播、可解码时间单元的提取、帧丢弃、缓冲区满时的关键帧插入清空行为、无效引用拒绝、重复帧拒绝、已解码帧拒绝。测试模拟了各种帧到达顺序（乱序、完整顺序、跳跃等）验证 `ExtractNextDecodableTemporalUnit` 的正确输出。
