# audio_decoder_L16

## 概述

`AudioDecoderL16` 是 WebRTC 中 L16（线性 PCM 16-bit）音频解码器的 API 结构体。L16 是一种未压缩的 PCM 编码格式，每个样本为 16 位有符号整数。该结构体定义了解码器配置参数（`Config`）以及用于工厂模板的三个核心静态方法：`SdpToConfig`、`AppendSupportedDecoders` 和 `MakeAudioDecoder`。实际解码工作委托给 `modules/audio_coding/codecs/pcm16b/` 中的 `AudioDecoderPcm16B`。

## 头文件接口 (.h)

**文件**: `api/audio_codecs/L16/audio_decoder_L16.h`

```cpp
struct RTC_EXPORT AudioDecoderL16 {
  struct Config {
    bool IsOk() const {
      return (sample_rate_hz == 8000 || sample_rate_hz == 16000 ||
              sample_rate_hz == 32000 || sample_rate_hz == 48000) &&
             (num_channels >= 1 &&
              num_channels <= AudioDecoder::kMaxNumberOfChannels);
    }
    int sample_rate_hz = 8000;    // 支持 8/16/32/48 kHz
    int num_channels = 1;          // 声道数
  };

  static std::optional<Config> SdpToConfig(const SdpAudioFormat& audio_format);
  static void AppendSupportedDecoders(std::vector<AudioCodecSpec>* specs);
  static std::unique_ptr<AudioDecoder> MakeAudioDecoder(
      const Config& config,
      std::optional<AudioCodecPairId> codec_pair_id = std::nullopt,
      const FieldTrialsView* field_trials = nullptr);
};
```

`Config::IsOk()` 校验采样率必须是 8、16、32 或 48 kHz，声道数在 `[1, kMaxNumberOfChannels]` 范围内。

## 实现文件 (.cc)

**文件**: `api/audio_codecs/L16/audio_decoder_L16.cc`

1. **`SdpToConfig()`**: 从 `SdpAudioFormat` 提取采样率（`format.clockrate_hz`）和声道数（`format.num_channels`），只有当 codec 名称不区分大小写匹配 `"L16"` 且 `Config::IsOk()` 通过时返回有效配置。

2. **`AppendSupportedDecoders()`**: 直接调用 `Pcm16BAppendSupportedCodecSpecs(specs)` 填充所有 L16 支持的 codec 规格。实际支持的规格由 `pcm16b_common.cc` 定义，通常包括各种采样率和声道组合。

3. **`MakeAudioDecoder()`**: 如果配置有效，创建并返回 `AudioDecoderPcm16B(sample_rate_hz, num_channels)` 实例。`AudioDecoderPcm16B` 是 `modules` 层真正的 PCM16B 解码器实现，继承自 `AudioDecoder`。

## 学习扩展

- **L16 格式**: 即 ITU-T G.711.1 附录中的线性 PCM，样本为 16 位有符号小端序。由于未压缩，码率计算为 `sample_rate * num_channels * 16` bps。
- **模块层级**: `api/audio_codecs/L16/` 是 API 层，实际编解码在 `modules/audio_coding/codecs/pcm16b/`。这种分层使 API 层只描述能力接口，不包含编解码实现。
- **PCM16B 含义**: PCM 16-bit Big-endian（大端序）的缩写，但 L16 实际存储格式取决于平台。

## 设计模式

- **外观模式 (Facade)**: `AudioDecoderL16` 结构体封装了 L16 解码器的创建过程，对外提供简洁的接口供工厂模板使用。
- **工厂模板参数**: 该结构体遵循 `CreateAudioDecoderFactory` 模板对 codec API 的约定（静态方法命名和签名），成为模板参数的一种协议（trait/concept）。
