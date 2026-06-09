# audio_encoder_opus_config

## 概述

`AudioEncoderOpusConfig` 是标准 Opus 编码器的完整配置结构体。它定义了 Opus 编码所需的所有参数：帧长、采样率、声道数、码率、FEC/DTX、复杂度及其自适应阈值等。这些参数覆盖了 Opus 库的功能集，并添加了 WebRTC 特有的码率自适应控制（如 `complexity_threshold_bps` 和 `low_rate_complexity`）。

## 头文件接口 (.h)

**文件**: `api/audio_codecs/opus/audio_encoder_opus_config.h`

```cpp
struct RTC_EXPORT AudioEncoderOpusConfig {
  static constexpr int kDefaultFrameSizeMs = 20;
  static constexpr int kMinBitrateBps = 6000;
  static constexpr int kMaxBitrateBps = 510000;

  int frame_size_ms;                                // 20ms
  int sample_rate_hz;                               // 48000
  size_t num_channels;                              // 声道数
  enum class ApplicationMode { kVoip, kAudio };
  ApplicationMode application;

  std::optional<int> bitrate_bps;                   // 编码码率，必须设置

  bool fec_enabled;                                 // 带内 FEC
  bool cbr_enabled;                                 // 恒定码率
  int max_playback_rate_hz;                         // 最大回放速率

  int complexity;                                   // 高码率时的复杂度
  int low_rate_complexity;                          // 低码率时的复杂度
  int complexity_threshold_bps;                     // 复杂度切换阈值
  int complexity_threshold_window_bps;              // 阈值窗口（防抖）

  bool dtx_enabled;                                 // 不连续传输
  std::vector<int> supported_frame_lengths_ms;      // 支持帧长列表
  int uplink_bandwidth_update_interval_ms;          // 上行带宽更新间隔

  int payload_type;                                 // 即将废弃
};
```

## 实现文件 (.cc)

**文件**: `api/audio_codecs/opus/audio_encoder_opus_config.cc`

**默认构造函数**:

```cpp
AudioEncoderOpusConfig::AudioEncoderOpusConfig()
    : frame_size_ms(kDefaultFrameSizeMs),       // 20
      sample_rate_hz(48000),
      num_channels(1),
      application(ApplicationMode::kVoip),
      bitrate_bps(32000),
      fec_enabled(false),
      cbr_enabled(false),
      max_playback_rate_hz(48000),
      complexity(kDefaultComplexity),            // 桌面端 9，移动端 5
      low_rate_complexity(kDefaultLowRateComplexity),
      complexity_threshold_bps(12500),
      complexity_threshold_window_bps(1500),
      dtx_enabled(false),
      uplink_bandwidth_update_interval_ms(200),
      payload_type(-1) {}
```

**平台相关的默认复杂度**:
- `WEBRTC_ANDROID` 或 `WEBRTC_IOS`: `kDefaultComplexity = 5`（移动设备 CPU 资源有限）
- 桌面端: `kDefaultComplexity = 9`
- `kDefaultLowRateComplexity = WEBRTC_OPUS_VARIABLE_COMPLEXITY ? 9 : kDefaultComplexity`: 当 `WEBRTC_OPUS_VARIABLE_COMPLEXITY` 宏开启时，低码率也使用全复杂度。

**`IsOk()` 校验**:
- `frame_size_ms > 0` 且为 10 的倍数。
- `sample_rate_hz` 必须为 16000 或 48000。
- `num_channels <= kMaxNumberOfChannels`。
- `bitrate_bps` 必须存在且在 `[6000, 510000]` 范围内。
- `complexity` 和 `low_rate_complexity` 必须在 `[0, 10]` 范围内。

## 学习扩展

- **双复杂度机制**: Opus 编码器支持在高码率（>12500+1500 bps）和低码率（<12500-1500 bps）使用不同的复杂度级别，中间区间使用最近一次的值。这种设计在低码率场景下节省 CPU 而不影响高码率质量。
- **默认码率 32kbps**: Opus 默认码率设置为 32000 bps，这是一个兼顾语音质量和带宽消耗的折中值。
- **上行带宽更新间隔 200ms**: 编码器每 200ms 更新一次上行带宽估计信息，用于码率自适应。
- **payload_type 即将废弃**: 注释指出 `payload_type` 成员不再必要（`TODO(bugs.webrtc.org/7847)`），将从编码器配置中移除，改由 factory 的 Options 提供。
- **VoIP vs Audio 模式**: `kVoip` 模式优化语音编码（在低码率下更好），`kAudio` 模式优化全频音乐编码。

## 设计模式

- **值对象 (Value Object)**: 配置结构体，可拷贝。
- **平台自适应默认值**: 通过预处理器宏（`WEBRTC_ANDROID` / `WEBRTC_IOS`）在不同平台设置不同的默认复杂度。
- **阈值窗口 (Threshold Window)**: 使用 hysteresis 窗口避免复杂度的频繁切换（乒乓效应）。
