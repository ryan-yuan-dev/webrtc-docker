# audio_encoder_factory_template_unittest

## 概述

该测试文件是 `audio_decoder_factory_template_unittest.cc` 的编码器版本，验证 `audio_encoder_factory_template.h` 中 `CreateAudioEncoderFactory<Codecs...>()` 模板工厂的正确性。由于编码器 factory 的接口比解码器多一个 `QueryAudioEncoder` 方法（用于在创建前查询编码器能力），测试覆盖更全面，包括 `GetSupportedEncoders`、`QueryAudioEncoder` 和 `Create` 三个主要方法。

## 测试内容

**测试辅助结构体**:

| 辅助类型 | 用途 |
|----------|------|
| `BogusParams` / `ShamParams` | 模拟假想的 codec 格式 |
| `AudioEncoderFakeApi<Params>` | 通用假 codec API（含 `QueryAudioEncoder`） |
| `BaseAudioEncoderApi` | 基础 trait，不含 MakeAudioEncoder |
| `AudioEncoderApiWithV1Make` | 只提供旧版 MakeAudioEncoder（带 payload_type） |
| `AudioEncoderApiWithV2Make` | 只提供新版 MakeAudioEncoder（带 Environment + Options） |
| `AudioEncoderApiWithBothV1AndV2Make` | 同时提供两个版本 |

**测试用例**:

| 测试名称 | 验证内容 |
|----------|----------|
| `UsesV1MakeAudioEncoderWhenV2IsNotAvailable` | 只有 V1 MakeAudioEncoder 时使用 V1 |
| `PreferV2MakeAudioEncoderWhenBothAreAvailable` | 两者都可用时优先使用 V2（带 Environment） |
| `CanUseTraitWithOnlyV2MakeAudioEncoder` | 只有 V2 时也能正常工作 |
| `NoEncoderTypes` | 空模板 -> 无支持的编码器、Query 返回 nullopt、Create 返回 nullptr |
| `OneEncoderType` | 单一 codec 类型测试 GetSupportedEncoders / QueryAudioEncoder / Create 三者 |
| `TwoEncoderTypes` | 多类型代码的聚合效果 |
| `G711` | 列出 PCMU/PCMA、QueryAudioEncoder 正确、创建时的 SDP 参数校验 |
| `G722` | G.722 编码器创建和查询 |
| `L16` | L16 编码器多采样率和多声道支持，包括 QueryAudioEncoder 中 bitrate 的计算 |
| `Opus` | Opus 编码器完整测试：码率范围、舒适噪声关闭、网络自适应开启、payload type 传参 |

## 学习扩展

- **V1 vs V2 API**: 编码器工厂模板支持两种 MakeAudioEncoder 签名：
  - V1: `MakeAudioEncoder(config, payload_type, codec_pair_id)`
  - V2: `MakeAudioEncoder(env, config, options)`
  当两者都存在时优先使用 V2，这是向后兼容的 API 升级策略。
- **QueryAudioEncoder**: 编码器 factory 特有的方法，在创建编码器之前查询其能力信息（如码率范围、声道数等），用于 SDP 协商阶段。
- 与解码器版本不同，编码器测试使用 `IsNull()` / `NotNull()` 匹配器（而非 `== nullptr`）和 `Pointer(Property(...))` 的组合进行更可读的断言。
- `Options` 结构体传递 `payload_type`，模拟了 SDP 协商后的实际创建场景。

## 设计模式

- **模板工厂测试 (Template Factory Test)**
- **集成测试 (Integration Test)**: 真实 codec 集成测试。
- **Mock 对象 (Mock Object)**: 模拟编码器。
