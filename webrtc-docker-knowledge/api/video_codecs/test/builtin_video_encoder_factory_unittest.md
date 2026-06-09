# builtin_video_encoder_factory_unittest

## 概述

测试 `CreateBuiltinVideoEncoderFactory()` 返回的工厂是否能根据编译标志正确宣布对 VP9 的支持。

## 测试用例

- `AnnouncesVp9AccordingToBuildFlags`：遍历工厂支持的格式，检查 `"VP9"` 是否在列表中。结果应匹配编译标志 `RTC_ENABLE_VP9` 的状态。
