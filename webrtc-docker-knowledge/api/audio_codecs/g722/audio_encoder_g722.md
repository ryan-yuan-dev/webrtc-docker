# audio_encoder_g722

## 概述

`AudioEncoderG722` 是 G.722 音频编码器的 API 结构体。与 `AudioDecoderG722` 对称，支持单声道和立体声编码。其 `Config` 类型实际是 `AudioEncoderG722Config`（在 `audio_encoder_g722_config.h` 中定义），包含 `frame_size_ms` 和 `num_channels` 两个字段。实际编码由 `modules/audio_coding/codecs/g722/audio_encoder_g722.h` 中的 `AudioEncoderG722Impl` 实现。

## 相关头文件 (`audio_encoder_g722_config.h`)

**文件**: `api/audio_codecs/g722/audio_encoder_g722_config.h`（仅 .h 文件，无对应 .cc）

```cpp
struct AudioEncoderG722Config {
  bool IsOk() const {
    return frame_size_ms > 0 && frame_size_ms % 10 == 0 && num_channels >= 1 &&
           num_channels <= AudioEncoder::kMaxNumberOfChannels;
  }
  int frame_size_ms = 20;          // 默认帧长 20ms
  int num_channels = 1;            // 声道数
};
```

这个独立的 config 结构体被 `AudioEncoderG722` 以 `using Config = AudioEncoderG722Config` 引用。

## 头文件接口 (.h)

**文件**: `api/audio_codecs/g722/audio_encoder_g722.h`

```cpp
struct RTC_EXPORT AudioEncoderG722 {
  using Config = AudioEncoderG722Config;

  static std::optional<AudioEncoderG722Config> SdpToConfig(
      const SdpAudioFormat& audio_format);
  static void AppendSupportedEncoders(std::vector<AudioCodecSpec>* specs);
  static AudioCodecInfo QueryAudioEncoder(const AudioEncoderG722Config& config);
  static std::unique_ptr<AudioEncoder> MakeAudioEncoder(
      const AudioEncoderG722Config& config,
      int payload_type,
      std::optional<AudioCodecPairId> codec_pair_id = std::nullopt,
      const FieldTrialsView* field_trials = nullptr);
};
```

## 实现文件 (.cc)

**文件**: `api/audio_codecs/g722/audio_encoder_g722.cc`

1. **`SdpToConfig()`**: 要求名称匹配 `"g722"`（不区分大小写）、`clockrate_hz == 8000`。解析 SDP 中的 `ptime` 参数设置 `frame_size_ms`，clamp 到 `[10, 60]` 范围。

2. **`AppendSupportedEncoders()`**: 通过 `SdpToConfig` 从默认格式构造 config，然后调用 `QueryAudioEncoder` 获取 info，构造 `AudioCodecSpec` 添加。

3. **`QueryAudioEncoder()`**: 返回 `{16000, num_channels, 64000 * num_channels}`。G.722 内部采样率为 16kHz，每声道固定 64kbps。

4. **`MakeAudioEncoder()`**: 创建 `AudioEncoderG722Impl(config, payload_type)` 实例。

## 学习扩展

- **Config 分离**: G.722 是唯一一个将编解码器的 config 定义在单独头文件中的内置 codec。`AudioEncoderG722Config` 在 `audio_encoder_g722_config.h` 中定义，`AudioEncoderG722::Config` 只是其别名。
- **SDP clockrate 不一致**: 与解码器一样，SDP 中使用 8000 Hz，但内部实际采样率为 16000 Hz。
- G.722 的默认帧长是 20ms（而非 L16 的 10ms），这是 VoIP 的标准设置。

## 设计模式

- **外观模式 (Facade)**: 封装 G.722 编码器创建过程。
- **工厂模板参数**: 遵循 `CreateAudioEncoderFactory` 的 trait 约定。
