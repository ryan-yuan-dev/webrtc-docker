# audio_encoder_multi_channel_opus

## 概述

`AudioEncoderMultiChannelOpus` 是多声道 Opus 编码器的 API 结构体，与 `AudioDecoderMultiChannelOpus` 对称。支持 5.1 和 7.1 环绕声的多声道 Opus 编码。其 `Config` 类型为 `AudioEncoderMultiChannelOpusConfig`（在 `audio_encoder_multi_channel_opus_config.h` 中定义）。实际编码委托给 `modules/audio_coding/codecs/opus/audio_encoder_multi_channel_opus_impl.h` 中的 `AudioEncoderMultiChannelOpusImpl`。

## 头文件接口 (.h)

**文件**: `api/audio_codecs/opus/audio_encoder_multi_channel_opus.h`

```cpp
struct RTC_EXPORT AudioEncoderMultiChannelOpus {
  using Config = AudioEncoderMultiChannelOpusConfig;

  static std::optional<Config> SdpToConfig(const SdpAudioFormat& audio_format);
  static void AppendSupportedEncoders(std::vector<AudioCodecSpec>* specs);
  static AudioCodecInfo QueryAudioEncoder(const Config& config);
  static std::unique_ptr<AudioEncoder> MakeAudioEncoder(
      const Config& config,
      int payload_type,
      std::optional<AudioCodecPairId> codec_pair_id = std::nullopt,
      const FieldTrialsView* field_trials = nullptr);
};
```

## 实现文件 (.cc)

**文件**: `api/audio_codecs/opus/audio_encoder_multi_channel_opus.cc`

1. **`SdpToConfig()`**: 委托给 `AudioEncoderMultiChannelOpusImpl::SdpToConfig(format)`。

2. **`AppendSupportedEncoders()`**: 与解码器版本完全相同，注册 5.1（6 声道/128kbps）和 7.1（8 声道/200kbps）两种环绕声规格。

3. **`QueryAudioEncoder()`**: 委托给 `AudioEncoderMultiChannelOpusImpl::QueryAudioEncoder(config)`。

4. **`MakeAudioEncoder()`**: 委托给 `AudioEncoderMultiChannelOpusImpl::MakeAudioEncoder(config, payload_type)`。

## 学习扩展

- **对称设计**: 编码器与解码器的多声道 Opus API 结构完全对称，都使用委托模式将调用转发到 `AudioEncoderMultiChannelOpusImpl` / `AudioDecoderMultiChannelOpusImpl`。
- **默认码率**: 5.1 环绕声默认 128kbps，7.1 环绕声默认 200kbps。这些码率相对于声道数来说相当高效，体现了 Opus 的优秀压缩性能。
- 此结构体在 `builtin_audio_encoder_factory.cc` 中被 `NotAdvertised<T>` 包装，不向 SDP 广播环绕声能力。

## 设计模式

- **外观模式 (Facade)**
- **委托模式 (Delegation)**: 所有静态方法都委托给 Impl 类实现。
