# builtin_audio_decoder_factory

## 概述

`CreateBuiltinAudioDecoderFactory()` 是一个便捷工厂函数，返回一个包含 WebRTC 所有内置音频解码器的 factory 对象。它通过 `CreateAudioDecoderFactory<TemplateArgs...>()` 模板函数组合了 Opus（单声道/多声道）、G722、G711 和 L16 解码器。如果只需要特定解码器，官方建议使用更细粒度的 `CreateAudioDecoderFactory<...>()` 或 `CreateOpusAudioDecoderFactory()`。

## 头文件接口 (.h)

**文件**: `api/audio_codecs/builtin_audio_decoder_factory.h`

```cpp
// 创建包含所有内置音频解码器的 factory
scoped_refptr<AudioDecoderFactory> CreateBuiltinAudioDecoderFactory();
```

只暴露一个函数签名，非常简洁。参数：无。返回值：`scoped_refptr<AudioDecoderFactory>`。

## 实现文件 (.cc)

**文件**: `api/audio_codecs/builtin_audio_decoder_factory.cc`

```cpp
scoped_refptr<AudioDecoderFactory> CreateBuiltinAudioDecoderFactory() {
  return CreateAudioDecoderFactory<
      AudioDecoderOpus,
      NotAdvertised<AudioDecoderMultiChannelOpus>,
      AudioDecoderG722,
      AudioDecoderG711,
      NotAdvertised<AudioDecoderL16>
  >();
}
```

关键实现细节：

1. **`NotAdvertised<T>` 模板包装器**: 一个适配器模板，它在 `AppendSupportedDecoders()` 中不添加任何 codec 信息到 `specs` 列表，即不向 SDP 协商广播该 codec 的支持。但 `SdpToConfig()` 和 `MakeAudioDecoder()` 仍正常返回，因此这些 codec 可以用于接收（解码）但不影响 SDP offer/answer。这用于：
   - `AudioDecoderMultiChannelOpus`: 多声道 Opus 虽可解码但不主动广播。
   - `AudioDecoderL16`: L16 用于接收但不主动广播。

2. **宏控制**: `#if WEBRTC_USE_BUILTIN_OPUS` 控制是否包含 Opus 相关的解码器类型。该宏在构建时由 GN 参数决定。

3. **组合策略**: factory 通过 variadic template 将多个 codec API struct 组合在一起，每个 struct 都遵循统一的约定（`SdpToConfig`、`AppendSupportedDecoders`、`MakeAudioDecoder`）。

## 学习扩展

- **Link-time 优化**: 头文件注释指出这个函数会链接所有 codec 的实现代码。如果只需要部分 codec，使用 `CreateAudioDecoderFactory<SpecificCodecs...>()` 可以减少二进制体积。
- **`NotAdvertised` 模板** 是典型的编译时策略模式，在零运行时开销下修改 codec 的行为。
- Opus 单声道解码器 (`AudioDecoderOpus`) 是主动广播的，而多声道解码器不广播。

## 设计模式

- **工厂方法模式 (Factory Method)**: 返回具体 `AudioDecoderFactory` 子类的实例。
- **编译时策略 (Compile-time Policy)**: `NotAdvertised<T>` 模板在编译时修改 codec 的广播行为。
- **变参模板 (Variadic Template)**: `CreateAudioDecoderFactory<Codecs...>()` 接受任意数量的 codec 类型参数，提供灵活的组合方式。
