# video_encoder_software_fallback_wrapper_unittest

## 概述

全面测试硬件编码器软件回退机制的正确性，包括基于分辨率的强制回退、基于时间层支持的强制回退、失败触发回退和 Field Trial 参数解析。

## 测试用例

- `InitializesEncoder`：正常初始化。
- `ForcedFallback` / `ForcedResolutionBasedFallback`：基于分辨率的强制回退。
- `ForcedTemporalBasedFallback`：基于时间层支持的强制回退。
- `FallbacksOnEncodeError`：编码错误触发回退。
- `StickyFallback`：回退粘性验证。
- `ReleasesHwEncoderOnFailedInit`：硬件初始化失败时释放。
- `UsesHwEncoderAfterReinit`：重新初始化后恢复硬件编码。
- `ForwardsEncoderSettings`：编码器参数正确转发。
- `ReportsFallbackImplementationName`：回退后实施名称报告格式。
- Field Trial 相关测试：验证 `WebRTC-VP8-Forced-Fallback-Encoder-v2` 和 `WebRTC-Video-EncoderFallbackSettings` 的配置解析。
