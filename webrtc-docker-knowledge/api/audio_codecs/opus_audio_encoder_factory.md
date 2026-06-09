# opus_audio_encoder_factory

## 概述

`CreateOpusAudioEncoderFactory()` 是 `CreateOpusAudioDecoderFactory()` 的对称函数，专门创建 Opus 音频编码器 factory。它等同于 `CreateAudioEncoderFactory<AudioEncoderOpus, AudioEncoderMultiChannelOpus>()`，组合了单声道和多声道 Opus 编码器。多声道编码器通过 `NotAdvertised` 包装以避免 SDP 广播。

## 头文件接口 (.h)

**文件**: `api/audio_codecs/opus_audio_encoder_factory.h`

```cpp
// 创建只能创建 Opus 音频编码器的 factory
scoped_refptr<AudioEncoderFactory> CreateOpusAudioEncoderFactory();
```

## 实现文件 (.cc)

**文件**: `api/audio_codecs/opus_audio_encoder_factory.cc`

```cpp
scoped_refptr<AudioEncoderFactory> CreateOpusAudioEncoderFactory() {
  return CreateAudioEncoderFactory<
      AudioEncoderOpus,
      NotAdvertised<AudioEncoderMultiChannelOpus>
  >();
}
```

与 `builtin_audio_encoder_factory.cc` 中的 `NotAdvertised<T>` 模板一致，只不过只包含 Opus 相关的两种编码器类型。

## 学习扩展

- **对称设计**: 编码器/解码器 factory 的设计完全对称，`AudioEncoderOpus` / `AudioDecoderOpus` 和 `AudioEncoderMultiChannelOpus` / `AudioDecoderMultiChannelOpus` 一一对应。
- 当应用只需要 Opus 编解码能力时，使用此函数代替 `CreateBuiltinAudioEncoderFactory()` 可以减少链接的 codec 代码。

## 设计模式

- **工厂方法模式 (Factory Method)**
- **编译时策略 (Compile-time Policy)**: `NotAdvertised<T>`
