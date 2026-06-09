# builtin_audio_encoder_factory

## 概述

`CreateBuiltinAudioEncoderFactory()` 是 `CreateBuiltinAudioDecoderFactory()` 的对称函数，返回包含 WebRTC 所有内置音频编码器的 factory 对象。它组合了 Opus（单声道/多声道）、G722、G711 和 L16 编码器。同样，如果只需要部分编码器，官方推荐使用更细粒度的工厂函数。

## 头文件接口 (.h)

**文件**: `api/audio_codecs/builtin_audio_encoder_factory.h`

```cpp
// 创建包含所有内置音频编码器的 factory
scoped_refptr<AudioEncoderFactory> CreateBuiltinAudioEncoderFactory();
```

接口与解码器版本完全相同：无参数，返回 `scoped_refptr<AudioEncoderFactory>`。

## 实现文件 (.cc)

**文件**: `api/audio_codecs/builtin_audio_encoder_factory.cc`

```cpp
scoped_refptr<AudioEncoderFactory> CreateBuiltinAudioEncoderFactory() {
  return CreateAudioEncoderFactory<
      AudioEncoderOpus,
      NotAdvertised<AudioEncoderMultiChannelOpus>,
      AudioEncoderG722,
      AudioEncoderG711,
      NotAdvertised<AudioEncoderL16>
  >();
}
```

与解码器版本结构一致：

1. **`NotAdvertised<T>`**: 与解码器类似，但模板方法不同：
   - `AppendSupportedEncoders()`: 不广播支持（空实现）。
   - `QueryAudioEncoder()`: 需要返回 `AudioCodecInfo`（解码器版本没有此方法）。
   - `MakeAudioEncoder()`: 参数多了一个 `payload_type` 和 `field_trials`。

2. **宏控制**: `#if WEBRTC_USE_BUILTIN_OPUS` 控制 Opus 的编译。

3. **`FieldTrialsView` 参数**: 编码器创建时需要 `field_trials` 字段试验配置，这是编码器 factory 与解码器 factory 的差异之一。

## 学习扩展

- **对称设计**: 编码器 factory 和解码器 factory 结构完全对称，遵循相同的组合模式，简化了 WebRTC 的 codec 管理。
- `NotAdvertised<T>` 中的 `QueryAudioEncoder` 方法需要返回 `AudioCodecInfo`，这用于在 SDP 协商前查询 codec 的能力信息。
- 编码器的 payload type 在 SDP 协商中确定，通过 `MakeAudioEncoder` 传入。

## 设计模式

- **工厂方法模式 (Factory Method)**: 创建具体 `AudioEncoderFactory` 实例。
- **编译时策略 (Compile-time Policy)**: `NotAdvertised<T>` 修改 codec 的广播行为。
- **变参模板 (Variadic Template)**: `CreateAudioEncoderFactory<Codecs...>()` 支持灵活组合。
