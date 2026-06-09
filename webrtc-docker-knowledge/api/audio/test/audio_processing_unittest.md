# audio_processing_unittest

## 概述

`audio_processing_unittest` 是 `CustomAudioProcessing()` 工厂函数的单元测试文件，验证自定义 APM 创建的路径。

## 测试用例

| 测试名 | 验证内容 |
|--------|----------|
| `ReturnsPassedAudioProcessing` | 通过 `CustomAudioProcessing()` 包装一个 MockAudioProcessing 实例，调用 Build() 后返回的实例与原始实例相同 |
| `NullptrAudioProcessingIsUnsupported` | **Death 测试**。传递 nullptr 给 CustomAudioProcessing() 会导致程序崩溃（`RTC_CHECK`），验证空指针保护 |

## 关键验证点

- `CustomAudioProcessing()` 返回的 Builder 对象是有效的（`NotNull`）。
- 返回的 Builder 的 `Build()` 方法忽略传入的 `Environment`，直接返回之前包装的 APM 实例。
- 不允许传递 nullptr，否则触发 `RTC_CHECK`（在 Debug 和 Release 模式下都会终止）。
