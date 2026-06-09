# audio_encoder_opus

## 概述

`AudioEncoderOpus` 是 WebRTC 中标准 Opus 编码器的 API 结构体。它是 `AudioDecoderOpus` 的对称编码器侧。其 `Config` 类型为 `AudioEncoderOpusConfig`（在 `audio_encoder_opus_config.h` 中定义）。实际编码委托给 `modules/audio_coding/codecs/opus/audio_encoder_opus.h` 中的 `AudioEncoderOpusImpl`。

与解码器版本的一个重要区别：`MakeAudioEncoder` 接受 `AudioEncoderFactory::Options` 而非 `std::optional<AudioCodecPairId>`，这是为了提供 factory 级别的选项（如 payload type）。

## 头文件接口 (.h)

**文件**: `api/audio_codecs/opus/audio_encoder_opus.h`

```cpp
struct RTC_EXPORT AudioEncoderOpus {
  using Config = AudioEncoderOpusConfig;

  static std::optional<AudioEncoderOpusConfig> SdpToConfig(
      const SdpAudioFormat& audio_format);
  static void AppendSupportedEncoders(std::vector<AudioCodecSpec>* specs);
  static AudioCodecInfo QueryAudioEncoder(const AudioEncoderOpusConfig& config);

  static std::unique_ptr<AudioEncoder> MakeAudioEncoder(
      const Environment& env,
      const AudioEncoderOpusConfig& config,
      const AudioEncoderFactory::Options& options);
};
```

注意：`MakeAudioEncoder` 接受 `AudioEncoderFactory::Options` 结构体，其中包含 `payload_type` 字段。

## 实现文件 (.cc)

**文件**: `api/audio_codecs/opus/audio_encoder_opus.cc`

所有方法都委托给 `AudioEncoderOpusImpl`：

1. **`SdpToConfig()`**: 委托给 `AudioEncoderOpusImpl::SdpToConfig(format)`。
2. **`AppendSupportedEncoders()`**: 委托给 `AudioEncoderOpusImpl::AppendSupportedEncoders(specs)`。
3. **`QueryAudioEncoder()`**: 委托给 `AudioEncoderOpusImpl::QueryAudioEncoder(config)`。
4. **`MakeAudioEncoder()`**: 校验 `config.IsOk()`，然后创建 `AudioEncoderOpusImpl(env, config, options.payload_type)`。

## 学习扩展

- **委托模式**: 与多声道版本一样，`AudioEncoderOpus` 将所有调用委托给 `AudioEncoderOpusImpl`。这种 API 层 / impl 层分离使得 API 层保持轻量、稳定，而 impl 层可以独立演进。
- **Options 参数**: 使用 `AudioEncoderFactory::Options` 而非单独传递 `payload_type` 和 `codec_pair_id`，这是 WebRTC 编解码器工厂接口演进的一部分。
- 标准 Opus 编码器以 `AudioEncoderOpus` 的形式被所有内置 factory 主动广播（没有被 `NotAdvertised` 包装）。

## 设计模式

- **外观模式 (Facade)**: 简化 Opus 编码器的创建过程。
- **委托模式 (Delegation)**: 将所有功能委托给 `AudioEncoderOpusImpl`。
- **工厂模板参数**: 遵循 `CreateAudioEncoderFactory` 的 trait 约定。
