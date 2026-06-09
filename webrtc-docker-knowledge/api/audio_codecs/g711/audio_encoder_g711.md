# audio_encoder_g711

## 概述

`AudioEncoderG711` 是 G.711 音频编码器的 API 结构体，与 `AudioDecoderG711` 对称。支持 PCMU（µ-law）和 PCMA（A-law）两种压扩律。编码器配置相比解码器多了 `frame_size_ms` 参数，用于指定每包的音频帧时长。实际编码由 `AudioEncoderPcmU` 和 `AudioEncoderPcmA` 实现。

## 头文件接口 (.h)

**文件**: `api/audio_codecs/g711/audio_encoder_g711.h`

```cpp
struct RTC_EXPORT AudioEncoderG711 {
  struct Config {
    enum class Type { kPcmU, kPcmA };
    bool IsOk() const {
      return (type == Type::kPcmU || type == Type::kPcmA) &&
             frame_size_ms > 0 && frame_size_ms % 10 == 0 &&
             num_channels >= 1 &&
             num_channels <= AudioEncoder::kMaxNumberOfChannels;
    }
    Type type = Type::kPcmU;
    int num_channels = 1;
    int frame_size_ms = 20;           // 默认 20ms 帧
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

## 实现文件 (.cc)

**文件**: `api/audio_codecs/g711/audio_encoder_g711.cc`

1. **`SdpToConfig()`**: 与解码器类似，检查 `"PCMU"` 或 `"PCMA"` 名称，要求 `clockrate_hz == 8000` 和 `num_channels >= 1`。额外解析 SDP 中的 `ptime` 参数来设置 `frame_size_ms`（默认 20ms），并 clamp 到 `[10, 60]` 范围。

2. **`AppendSupportedEncoders()`**: 明确列出 PCMU 和 PCMA 两种规格，均为 8kHz、单声道、64kbps。

3. **`QueryAudioEncoder()`**: 返回 `{8000, num_channels, 64000 * num_channels}`。G.711 固定码率为每声道 64kbps。

4. **`MakeAudioEncoder()`**: 根据 `config.type`：
   - `kPcmU`: 构造 `AudioEncoderPcmU`，设置 `num_channels`、`frame_size_ms` 和 `payload_type`。
   - `kPcmA`: 构造 `AudioEncoderPcmA`，同上。

## 学习扩展

- **帧长默认值**: G.711 解码器不涉及帧长概念（逐样本解码），但编码器需要将多个 10ms 块打包为一个 RTP 包。默认 20ms 是 VoIP 的标准值，平衡了延迟和带宽效率。
- **固定码率**: `QueryAudioEncoder` 返回的 `min_bitrate_bps == max_bitrate_bps == default_bitrate_bps`，表示该 codec 具有固定码率。
- G.711 的 RTP payload format 在 RFC 3551 中定义，PCMU 静态 payload type 为 0，PCMA 为 8。

## 设计模式

- **外观模式 (Facade)**: 封装 PCMU/PCMA 编码器创建。
- **工厂模板参数**: 遵循 `CreateAudioEncoderFactory` 的 trait 约定。
