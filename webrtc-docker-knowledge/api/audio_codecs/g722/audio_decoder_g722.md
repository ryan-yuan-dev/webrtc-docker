# audio_decoder_g722

## 概述

`AudioDecoderG722` 是 WebRTC 中 G.722 音频解码器的 API 结构体。G.722 是 ITU-T 定义的一种宽带音频编解码器，采样率为 16kHz，是 VoIP 中常用的高质量音频编解码器。该结构体定义了单声道和立体声两种解码模式。实际解码由 `modules/audio_coding/codecs/g722/audio_decoder_g722.h` 中的 `AudioDecoderG722Impl`（单声道）和 `AudioDecoderG722StereoImpl`（立体声）实现。

## 头文件接口 (.h)

**文件**: `api/audio_codecs/g722/audio_decoder_g722.h`

```cpp
struct RTC_EXPORT AudioDecoderG722 {
  struct Config {
    bool IsOk() const { return num_channels == 1 || num_channels == 2; }
    int num_channels;
  };

  static std::optional<Config> SdpToConfig(const SdpAudioFormat& audio_format);
  static void AppendSupportedDecoders(std::vector<AudioCodecSpec>* specs);
  static std::unique_ptr<AudioDecoder> MakeAudioDecoder(
      Config config,
      std::optional<AudioCodecPairId> codec_pair_id = std::nullopt,
      const FieldTrialsView* field_trials = nullptr);
};
```

`Config` 只包含 `num_channels` 字段，取值必须为 1（单声道）或 2（立体声）。

注意：`MakeAudioDecoder` 的参数 `config` 是传值（`Config config`），而其他解码器多使用 `const Config&` 或 `const Config& config`。

## 实现文件 (.cc)

**文件**: `api/audio_codecs/g722/audio_decoder_g722.cc`

1. **`SdpToConfig()`**: 检查 SDP 格式名称是否为 `"G722"`（不区分大小写），时钟频率是否为 8000 Hz，声道数是否为 1 或 2。注意 G.722 的 SDP clockrate 为 8000，但实际内部采样率为 16000 Hz（这是 G.722 的 RTP 封装惯例）。

2. **`AppendSupportedDecoders()`**: 添加单个规格 `{"G722", 8000, 1}` 对应 `{16000, 1, 64000}`。即单声道、16000 Hz 采样率、64 kbps 码率。

3. **`MakeAudioDecoder()`**: 根据声道数：
   - `num_channels == 1`: 创建 `AudioDecoderG722Impl`
   - `num_channels == 2`: 创建 `AudioDecoderG722StereoImpl`

## 学习扩展

- **G.722 RTP 封装的特殊性**: G.722 内部采样率为 16kHz，但 RTP 时间戳以 8kHz 递增（RFC 3551）。因此 SDP 中 `clockrate_hz` 为 8000，但实际输出采样率为 16000 Hz。`AudioCodecInfo` 中的 `sample_rate_hz` 为 16000 反映了这一事实。
- **码率**: G.722 固定码率为 64kbps（实际是 48/56/64 kbps 可变，但 WebRTC 固定为 64kbps），以 64kbit/s（每声道），立体声为 128kbps。
- **G.722.1 / G.722.2**: G.722 系列还包括 G.722.1（14kHz 带宽）和 G.722.2（AMR-WB，扩展为 7kHz 音频带宽），但 WebRTC 只内置了 G.722。

## 设计模式

- **外观模式 (Facade)**: 封装 G.722 解码器的创建过程。
- **工厂模板参数**: 遵循 `CreateAudioDecoderFactory` 的 trait 约定。
