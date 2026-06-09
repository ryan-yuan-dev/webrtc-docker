# audio_encoder_L16

## 概述

`AudioEncoderL16` 是 L16（线性 PCM 16-bit）音频编码器的 API 结构体，与 `AudioDecoderL16` 对称。它定义了编码器配置参数（`Config`）和工厂模板所需的三个静态方法。此外增加了 `QueryAudioEncoder()` 方法，返回编码器的能力信息（`AudioCodecInfo`）。实际编码工作委托给 `modules/audio_coding/codecs/pcm16b/audio_encoder_pcm16b.h` 中的 `AudioEncoderPcm16B`。

## 头文件接口 (.h)

**文件**: `api/audio_codecs/L16/audio_encoder_L16.h`

```cpp
struct RTC_EXPORT AudioEncoderL16 {
  struct Config {
    bool IsOk() const {
      return (sample_rate_hz == 8000 || sample_rate_hz == 16000 ||
              sample_rate_hz == 32000 || sample_rate_hz == 48000) &&
             num_channels >= 1 &&
             num_channels <= AudioEncoder::kMaxNumberOfChannels &&
             frame_size_ms > 0 && frame_size_ms <= 120 &&
             frame_size_ms % 10 == 0;
    }
    int sample_rate_hz = 8000;
    int num_channels = 1;
    int frame_size_ms = 10;                           // 帧长（ms），10ms 的整数倍
  };

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

与 `AudioDecoderL16` 相比，`Config` 多了 `frame_size_ms` 字段，默认 10ms，且必须大于 0、能被 10 整除、不超过 120ms。

## 实现文件 (.cc)

**文件**: `api/audio_codecs/L16/audio_encoder_L16.cc`

1. **`SdpToConfig()`**: 从 `SdpAudioFormat` 提取参数。额外解析 SDP 中的 `ptime` 参数（packetization time），将其向下取整到 10ms 的倍数，并 clamp 到 `[10, 60]` 范围。

2. **`AppendSupportedEncoders()`**: 调用 `Pcm16BAppendSupportedCodecSpecs(specs)`，与解码器共享同一辅助函数。

3. **`QueryAudioEncoder()`**: 返回 `{sample_rate_hz, num_channels, sample_rate_hz * num_channels * 16}`。L16 的码率就是 `采样率 × 声道数 × 16` bps，因为每个样本 16 位。

4. **`MakeAudioEncoder()`**: 构造 `AudioEncoderPcm16B::Config`，设置 `sample_rate_hz`、`num_channels`、`frame_size_ms` 和 `payload_type`，然后创建 `AudioEncoderPcm16B` 实例。

## 学习扩展

- **码率计算**: L16 是未压缩编码，码率固定为 `采样率 * 声道数 * 16`。例如 48kHz 立体声 = 48000 * 2 * 16 = 1,536,000 bps（约 1.5 Mbps），带宽占用很大。
- **ptime 参数**: SDP 中的 `ptime` 表示每个 RTP 数据包中包含的音频时长（毫秒）。`SdpToConfig` 会解析并据此设置 `frame_size_ms`。
- **帧长范围**: L16 的帧长必须在 10ms-120ms 之间且为 10ms 的倍数，10ms 是 WebRTC 音频处理的基本时间单位。

## 设计模式

- **外观模式 (Facade)**: 封装 PCM16B 编码器的创建过程。
- **工厂模板参数**: 遵循音频编码器 factory 模板约定。
