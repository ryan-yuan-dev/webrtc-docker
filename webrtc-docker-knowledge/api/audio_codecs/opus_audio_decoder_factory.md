# opus_audio_decoder_factory

## 概述

`CreateOpusAudioDecoderFactory()` 是专门创建 Opus 音频解码器 factory 的便捷函数。它等同于 `CreateAudioDecoderFactory<AudioDecoderOpus, AudioDecoderMultiChannelOpus>()`，但以非模板函数的形式提供，在链接体积上更友好。生成的 factory 可以创建单声道 Opus 解码器和多声道 Opus 解码器，但多声道 Opus 解码器不被广播（`NotAdvertised` 包装）。

## 头文件接口 (.h)

**文件**: `api/audio_codecs/opus_audio_decoder_factory.h`

```cpp
// 创建只能创建 Opus 音频解码器的 factory
scoped_refptr<AudioDecoderFactory> CreateOpusAudioDecoderFactory();
```

## 实现文件 (.cc)

**文件**: `api/audio_codecs/opus_audio_decoder_factory.cc`

```cpp
scoped_refptr<AudioDecoderFactory> CreateOpusAudioDecoderFactory() {
  return CreateAudioDecoderFactory<
      AudioDecoderOpus,
      NotAdvertised<AudioDecoderMultiChannelOpus>
  >();
}
```

使用与 `builtin_audio_decoder_factory` 中相同的 `NotAdvertised<T>` 模板包装器，使多声道 Opus 解码器不参与 SDP 功能广播（但可以用于接收多声道流）。

## 学习扩展

- **分工明确**: `AudioDecoderOpus` 用于标准 Opus（1-2 声道），`AudioDecoderMultiChannelOpus` 用于环绕声（5.1、7.1 等多声道）。
- 如果在编译时禁用了 WebRTC 内置 Opus（`WEBRTC_USE_BUILTIN_OPUS` 为 false），则不应调用此函数。
- 与 `CreateBuiltinAudioDecoderFactory()` 相比，此工厂只链接 Opus 相关代码，减少二进制体积。

## 设计模式

- **工厂方法模式 (Factory Method)**
- **编译时策略 (Compile-time Policy)**: `NotAdvertised<T>`
