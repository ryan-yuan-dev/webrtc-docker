# video_decoder_software_fallback_wrapper_unittest

## 概述

全面测试硬件解码器软件回退机制的正确性，包括初始化、回退触发、回退粘性、释放转发和强制回退功能。

## 测试用例

- `InitializesDecoder`：正常初始化后硬件解码器被使用。
- `UsesFallbackDecoderAfterAnyInitDecodeFailure`：硬件配置失败后使用软件回退。
- `IsSoftwareFallbackSticky`：回退后不会切换回硬件解码器。
- `DoesNotFallbackOnEveryError`：单次错误不会触发回退（仅累计关键帧错误）。
- `UsesHwDecoderAfterReinit`：Release+Configure 后重新使用硬件解码器。
- `ForwardsReleaseCall`：验证 Release 调用的正确转发。
- `ForwardsRegisterDecodeCompleteCallback`：验证回调注册的转发。
- `ReportsFallbackImplementationName`：验证回退状态下的名称报告格式。
- `FallbacksOnTooManyErrors`：验证超过 4 次连续关键帧错误后触发回退。
- `DoesNotFallbackOnDeltaFramesErrors`：Delta 帧错误不触发回退。
- `DoesNotFallbacksOnNonConsequtiveErrors`：非连续错误不触发回退。
- `UsesForcedFallback`：Field Trial 强制回退开关验证。
