# audio_encoder_multi_channel_opus_config

## 概述

`AudioEncoderMultiChannelOpusConfig` 是多声道 Opus 编码器的完整配置结构体。定义了从帧长、码率、FEC/DTX 开关到复杂的流/声道映射（stream/channel mapping）等所有编码参数。它位于 `audio_encoder_multi_channel_opus_config.h` 和 `.cc` 文件中，被 `AudioEncoderMultiChannelOpus` 以 `using Config = AudioEncoderMultiChannelOpusConfig` 引用。

## 头文件接口 (.h)

**文件**: `api/audio_codecs/opus/audio_encoder_multi_channel_opus_config.h`

```cpp
struct RTC_EXPORT AudioEncoderMultiChannelOpusConfig {
  static constexpr int kDefaultFrameSizeMs = 20;
  static constexpr int kMinBitrateBps = 6000;
  static constexpr int kMaxBitrateBps = 510000;

  int frame_size_ms;                              // 帧长（ms），10 的整数倍
  size_t num_channels;                            // 输入声道数
  enum class ApplicationMode { kVoip, kAudio };   // VoIP 模式或音频模式
  ApplicationMode application;
  int bitrate_bps;                                // 编码码率
  bool fec_enabled;                               // 是否启用带内 FEC
  bool cbr_enabled;                               // 是否启用恒定码率
  bool dtx_enabled;                               // 是否启用 DTX
  int max_playback_rate_hz;                       // 解码器最大回放速率
  std::vector<int> supported_frame_lengths_ms;    // 支持的帧长列表

  int complexity;                                 // 编码复杂度 [0, 10]

  int num_streams;                                // 编码流数量
  int coupled_streams;                            // 耦合流（立体声对）数量
  std::vector<unsigned char> channel_mapping;     // 声道映射表

  bool IsOk() const;
};
```

## 实现文件 (.cc)

**文件**: `api/audio_codecs/opus/audio_encoder_multi_channel_opus_config.cc`

**默认构造函数**:
```cpp
AudioEncoderMultiChannelOpusConfig::AudioEncoderMultiChannelOpusConfig()
    : frame_size_ms(kDefaultFrameSizeMs),  // 20ms
      num_channels(1),
      application(ApplicationMode::kVoip),
      bitrate_bps(32000),
      fec_enabled(false),
      cbr_enabled(false),
      dtx_enabled(false),
      max_playback_rate_hz(48000),
      complexity(kDefaultComplexity),  // 9
      num_streams(-1),
      coupled_streams(-1) {}
```

拷贝/移动构造函数和赋值运算符均为 `= default`。

**`IsOk()` 校验逻辑**:

1. 基本校验:
   - `frame_size_ms > 0` 且为 10 的倍数。
   - `num_channels <= kMaxNumberOfChannels`。
   - `bitrate_bps` 在 `[6000, 510000]` 范围内。
   - `complexity` 在 `[0, 10]` 范围内。

2. 流/声道映射校验:
   - `num_streams >= 0`, `coupled_streams >= 0`。
   - `num_streams >= coupled_streams`（耦合流不能超过总流数）。
   - `channel_mapping.size() == num_channels`。

3. 声道映射有效性:
   - `max_coded_channel = num_streams + coupled_streams`（总编码声道数）。
   - 每个映射值必须 `< max_coded_channel` 或等于 `255`（255 表示忽略该输入声道）。
   - **逆映射检查**: 每个编码声道必须恰好对应一个输入声道（双向映射的一对一性），确保不会出现两个输入声道映射到同一编码声道。
   - `num_channels < 255` 且 `max_coded_channel < 255`。

## 学习扩展

- **kDefaultComplexity = 9**: 预定义的默认复杂度（桌面端）。WebRTC 在不同平台上选择不同的默认复杂度以平衡编码质量和 CPU 消耗。
- **RFC 7845**: Opus 的多声道编码规范。`num_streams`、`coupled_streams` 和 `channel_mapping` 均遵循该 RFC 的定义：
  - 每个 mono stream 编码 1 个声道，每个 coupled stream 编码 2 个声道（立体声）。
  - `channel_mapping` 是长度为 `num_channels` 的数组，告诉编码器每个输入声道使用哪个编码声道。
- **码率范围**: 6kbps - 510kbps，由 Opus 库本身限制。500bps 是 Opus API 的下限，但实际建议不低于 6kbps。
- **逆映射验证**: `IsOk()` 中构造 `coded_channels_to_input_channels` 逆映射数组的做法确保了配置的声道分配是完整且无冲突的。

## 设计模式

- **值对象 (Value Object)**: 可拷贝、可比较的配置数据结构。
- **自校验 (Self-Validation)**: `IsOk()` 方法复杂地校验了多声道配置的所有约束，确保配置在传入 Opus 库之前是有效的。
