# video_codec_unittest

## 概述

测试 `VideoCodec::IsMixedCodec()` 方法的正确性，验证混合编解码器 Simulcast 场景的检测逻辑。

## 测试用例

- `TestIsMixedCodec`：覆盖各种场景：
  - 空流列表、单流、多流相同编解码器 -> 非混合。
  - 不同编解码器组合（VP8+VP9、VP9 Profile0+Profile1） -> 混合。
  - 仅部分设置 format -> 非混合。
  - 非活动流的 format 被忽略。
