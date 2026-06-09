# frame_instrumentation_generator_unittest

## 概述

`FrameInstrumentationGenerator` 的单元测试，验证发送端检测数据生成器的完整行为。测试覆盖：`OnCapturedFrame` 和 `OnEncodedImage` 的配对处理、关键帧同步消息生成、非关键帧采样数据生成、Halton 序列索引管理、层间上下文隔离、QP 缺失时的 QP 解析和 filter settings 生成、帧超时丢弃逻辑（kMaxPendingFrames）、多空间层的独立上下文管理。
