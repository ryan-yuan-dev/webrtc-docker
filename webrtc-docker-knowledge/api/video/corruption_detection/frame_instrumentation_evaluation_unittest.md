# frame_instrumentation_evaluation_unittest

## 概述

`FrameInstrumentationEvaluation` 的单元测试，验证接收端 corruption 评估组件的正确行为。测试包括：`Create` 工厂方法的 null observer 拒绝、`OnInstrumentedFrame` 的 sync 消息静默忽略、接收帧的采样坐标提取和 corrupted score 计算回调。
