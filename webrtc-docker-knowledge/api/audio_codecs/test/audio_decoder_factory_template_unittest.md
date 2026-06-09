# audio_decoder_factory_template_unittest

## 概述

该测试文件验证 `audio_decoder_factory_template.h` 中 `CreateAudioDecoderFactory<Codecs...>()` 模板工厂的正确性。测试覆盖了 template 工厂的主要功能点：空类型列表、单类型、多类型、各内置 codec（G711、G722、L16、Opus）的创建和查询、Environment 传递的优先级，以及边界条件（如声道数过多）。

## 测试内容

**测试辅助结构体**:

| 辅助类型 | 用途 |
|----------|------|
| `BogusParams` / `ShamParams` | 模拟两种假想的 codec 格式，用于测试单类型和多类型工厂 |
| `AudioDecoderFakeApi<Params>` | 通用假 codec API，模拟工厂模板所需的静态方法 |
| `BaseAudioDecoderApi` | 不包含 `MakeAudioDecoder` 的基础 trait |
| `TraitWithTwoMakeAudioDecoders` | 提供两种 `MakeAudioDecoder` 重载（带/不带 Environment） |

**测试用例**:

| 测试名称 | 验证内容 |
|----------|----------|
| `PrefersToPassEnvironmentToMakeAudioDecoder` | 当 codec 同时提供带 Environment 和不带 Environment 的 MakeAudioDecoder 时，工厂优先使用带 Environment 的版本 |
| `CanUseMakeAudioDecoderWithoutPassingEnvironment` | 如果 codec 只提供旧的 MakeAudioDecoder（无 Environment），工厂仍能正常工作 |
| `NoDecoderTypes` | 空模板参数列表时，工厂无支持的解码器、不识别任何格式、创建返回 nullptr |
| `OneDecoderType` | 单一 codec 类型的工厂能够列出/识别/创建对应解码器 |
| `TwoDecoderTypes` | 多 codec 类型的工厂能够正确聚合两个 codec 的能力信息 |
| `G711` | G.711 解码器的实际集成测试：列出 PCMU/PCMA，区分大小写不敏感，拒绝错误的采样率 |
| `G722` | G.722 解码器测试：单声道/立体声创建，声道数限制检查 |
| `L16` | L16 解码器测试：验证支持的所有采样率和声道组合，拒绝无效采样率（96000）和声道数（0） |
| `Opus` | Opus 解码器测试：码率范围（6000-510000）、舒适噪声关闭、网络自适应开启、检查声道数为 2 的 SDP 格式 |
| `G711TooManyChannels` | 边界测试：G.711 拒绝声道数为 1000 的无效请求 |

## 学习扩展

- **Mock 测试**: 使用 `MockAudioDecoder` 模拟解码器行为，通过 `EXPECT_CALL` 验证创建时 `SampleRateHz` 被正确调用，以及析构时 `Die()` 被调用（确保资源正确释放）。
- **Environment 优先级**: 该测试验证了 codec API 的一种演化方向 —— 优先使用接受 `Environment` 参数的 `MakeAudioDecoder`，因为 Environment 提供了 field trials、任务队列等更丰富的运行时上下文。
- **FactoryT<...> 空模板**: 测试直接使用 `audio_decoder_factory_template_impl::AudioDecoderFactoryT<>` 创建空 factory，验证变参模板支持零参数的情况。
- `StrictMock` 用于 `AudioDecoderFakeApi::MakeAudioDecoder` 中的解码器创建，确保 mock 对象的所有预期行为都被验证过再销毁。

## 设计模式

- **模板工厂测试 (Template Factory Test)**: 验证 `CreateAudioDecoderFactory<Codecs...>()` 变参模板工厂的正确行为。
- **集成测试 (Integration Test)**: 使用真实的内置 codec（G711、G722、L16、Opus）验证端到端的解码器创建流程。
- **Mock 对象 (Mock Object)**: 使用 gMock 模拟解码器行为，隔离测试工厂层的逻辑。
