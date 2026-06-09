# builtin_audio_processing_builder_unittest

## 概述

`builtin_audio_processing_builder_unittest` 是 `BuiltinAudioProcessingBuilder` 的单元测试文件，验证 Builder 创建 APM 实例的基本功能。

## 测试用例

| 测试名 | 验证内容 |
|--------|----------|
| `CreatesWithDefaults` | 使用默认配置创建 APM 实例，返回非空指针 |
| `CreatesWithConfig` | 通过 `BuiltinAudioProcessingBuilder(config)` 和 `BuiltinAudioProcessingBuilder().SetConfig(config)` 两种方式创建 APM，验证创建的 APM 配置与传入配置一致 |

## 关键验证点

- 默认配置下 `Build()` 返回非空 `scoped_refptr<AudioProcessing>`。
- 两种 Builder 使用方式（构造函数传参和 `SetConfig()` 链式调用）效果等价。
- 创建的 APM 实例应返回正确的配置（`GetConfig()` 与传入配置一致）。
