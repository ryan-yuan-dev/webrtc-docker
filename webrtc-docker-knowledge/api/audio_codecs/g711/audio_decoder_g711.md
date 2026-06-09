# audio_decoder_g711

## 概述

`AudioDecoderG711` 是 WebRTC 中 G.711 音频解码器的 API 结构体。G.711 是 ITU-T 定义的脉冲编码调制（PCM）音频编码标准，包含两种压扩律（companding law）：**PCMU**（µ-law/Mu-law）和 **PCMA**（A-law）。该结构体定义了解码器配置和工厂模板所需的静态方法。实际解码工作委托给 `modules/audio_coding/codecs/g711/audio_decoder_pcm.h` 中的 `AudioDecoderPcmU` 和 `AudioDecoderPcmA`。

## 头文件接口 (.h)

**文件**: `api/audio_codecs/g711/audio_decoder_g711.h`

```cpp
struct RTC_EXPORT AudioDecoderG711 {
  struct Config {
    enum class Type { kPcmU, kPcmA };
    bool IsOk() const {
      return (type == Type::kPcmU || type == Type::kPcmA) &&
             num_channels >= 1 &&
             num_channels <= AudioDecoder::kMaxNumberOfChannels;
    }
    Type type;               // PCMU 或 PCMA
    int num_channels;        // 声道数
  };

  static std::optional<Config> SdpToConfig(const SdpAudioFormat& audio_format);
  static void AppendSupportedDecoders(std::vector<AudioCodecSpec>* specs);
  static std::unique_ptr<AudioDecoder> MakeAudioDecoder(
      const Config& config,
      std::optional<AudioCodecPairId> codec_pair_id = std::nullopt,
      const FieldTrialsView* field_trials = nullptr);
};
```

## 实现文件 (.cc)

**文件**: `api/audio_codecs/g711/audio_decoder_g711.cc`

1. **`SdpToConfig()`**: 检查 SDP 格式名称是否为 `"PCMU"` 或 `"PCMA"`（不区分大小写），且时钟频率为 8000 Hz，声道数 >= 1。然后根据名称设置 `Config::Type` 和 `num_channels`。

2. **`AppendSupportedDecoders()`**: 明确列出两个规格：
   - `{"PCMU", 8000, 1}` 对应 `{8000, 1, 64000}`
   - `{"PCMA", 8000, 1}` 对应 `{8000, 1, 64000}`
   即 G.711 始终为 8kHz 采样率、每声道 64kbps 固定码率。

3. **`MakeAudioDecoder()`**: 根据 `config.type`：
   - `kPcmU`: 创建 `AudioDecoderPcmU(num_channels)`
   - `kPcmA`: 创建 `AudioDecoderPcmA(num_channels)`

## 学习扩展

- **µ-law vs A-law**: µ-law 主要用于北美和日本，A-law 主要用于欧洲和世界其他地区。两者都实现 8kHz 采样率、8 位/样本的压缩 PCM，有效比特率 64kbps。
- **G.711 特性**: 固定码率、极低延迟、广泛兼容。虽然压缩比不高（原始 PCM 约为 128kbps），但它是最基础的 VoIP 编解码器。
- **RTP 格式**: PCMU 的 RTP payload type 通常为 0，PCMA 通常为 8（标准静态分配）。

## 设计模式

- **外观模式 (Facade)**: 封装 PCMU/PCMA 解码器创建。
- **工厂模板参数**: 遵循 `CreateAudioDecoderFactory` 的 trait 约定。
