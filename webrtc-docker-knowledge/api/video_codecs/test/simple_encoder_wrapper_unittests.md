# simple_encoder_wrapper_unittests

## 概述

测试 `SimpleEncoderWrapper` 的 SVC 模式生成和实际编码流程的正确性。

## 测试用例

- `SupportedSvcModesOnlyL1T1`：只有单个缓冲区、单层时间层、单空间层时生成 `["L1T1"]`。
- `SupportedSvcModesUpToL1T3`：3 个时间层、1 个空间层时生成 `["L1T1", "L1T2", "L1T3"]`。
- `SupportedSvcModesUpToL3T3Key`：多个空间层和时间层时的完整模式组合。
