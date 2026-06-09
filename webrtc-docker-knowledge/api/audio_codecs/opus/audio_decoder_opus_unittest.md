# audio_decoder_opus_unittest

## 概述

该测试文件验证 `AudioDecoderOpus` 的 `SdpToConfig` 和 `MakeAudioDecoder` 方法的正确性。重点关注 `SdpAudioFormat` 中的 `stereo` 参数解析和 `MakeAudioDecoder` 在默认/强制声道数下的行为。还测试了 `WebRTC-Audio-OpusDecodeStereoByDefault` field trial 对解码器默认声道数的影响。

## 测试内容

**测试用例**:

| 测试名称 | 验证内容 |
|----------|----------|
| `SdpToConfigDoesNotSetNumChannels` | 当 SDP 格式中未设置 `stereo` 参数时，`SdpToConfig` 返回的 `Config::num_channels` 为 `std::nullopt`（由解码器运行时决定） |
| `SdpToConfigForcesMono` | SDP 中 `stereo=0` 时，`Config::num_channels` 被设置为 1 |
| `SdpToConfigForcesStereo` | SDP 中 `stereo=1` 时，`Config::num_channels` 被设置为 2 |
| `MakeAudioDecoderForcesDefaultNumChannels` | `num_channels = nullopt` 且无 field trial 时，解码器默认输出 1 声道 |
| `MakeAudioDecoderCannotForceDefaultNumChannels` | 当显式指定 `num_channels = 2` 时，解码器输出 2 声道（即使无 field trial） |
| `MakeAudioDecoderForcesStereo` | 启用 field trial `WebRTC-Audio-OpusDecodeStereoByDefault` 后，`num_channels = nullopt` 时解码器默认输出 2 声道 |
| `MakeAudioDecoderCannotForceStereo` | 即使启用 field trial，显式指定 `num_channels = 1` 时解码器仍输出 1 声道（explicit config 优先级更高） |

**辅助函数 `GetSdpAudioFormat(StereoParam)`**:
- `StereoParam::kUnset`: 格式中不包含 `stereo` 参数。
- `StereoParam::kMono`: 包含 `stereo=0`。
- `StereoParam::kStereo`: 包含 `stereo=1`。

## 学习扩展

- **优先级规则**: Field trial 优先级的体现 —— `Config` 中的显式设置  >  Field trial 默认值 > 代码中的硬编码默认值。
- **匹配器用法**: 使用 `Optional(Field(&Config::num_channels, value))` 组合匹配器，简洁地验证 `std::optional` 中的字段值。
- **CreateTestFieldTrialsPtr**: 使用 `CreateTestFieldTrialsPtr("WebRTC-Audio-OpusDecodeStereoByDefault/Enabled/")` 创建测试用的 field trials，在不修改全局状态的情况下模拟启用某个 field trial。
- Opus 解码器的 `SdpToConfig` 只解析 `stereo` 参数，不设置默认声道数；默认声道数的决定延迟到 `MakeAudioDecoder` 阶段，使字段试验可以介入。

## 设计模式

- **单元测试 (Unit Test)**: 聚焦 `AudioDecoderOpus` 的静态方法，使用 gtest 和 gmock 进行断言。
- **参数化测试风格**: 虽然未使用 gtest 的 `TEST_P`，但通过 `StereoParam` 枚举和 `GetSdpAudioFormat` 辅助函数实现了类似的测试逻辑复用。
