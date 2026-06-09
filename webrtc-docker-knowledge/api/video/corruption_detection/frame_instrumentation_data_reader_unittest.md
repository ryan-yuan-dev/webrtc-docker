# frame_instrumentation_data_reader_unittest

## 概述

`FrameInstrumentationDataReader` 的单元测试，验证 `ParseMessage` 对携带高位信息和增量信息的 `CorruptionDetectionMessage` 的解析正确性。测试包括：高位序列索引的设置、增量更新时序列索引的包裹恢复、同步消息（无采样值）的处理、采样值数据的完整提取。
