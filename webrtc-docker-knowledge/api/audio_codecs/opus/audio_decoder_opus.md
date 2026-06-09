# audio_decoder_opus

## 概述

`AudioDecoderOpus` 是 WebRTC 中标准 Opus 解码器的 API 结构体。Opus 是一个高灵活性、低延迟的音频编解码器，支持从 narrowband 到 fullband 的多种采样率、单声道和立体声、以及码率自适应。该结构体定义了单声道 Opus 解码器的配置和工厂方法。`MakeAudioDecoder` 方法接受 `Environment` 参数，体现了 WebRTC 编解码器创建向 Environment 机制迁移的趋势。

## 头文件接口 (.h)

**文件**: `api/audio_codecs/opus/audio_decoder_opus.h`

```cpp
struct RTC_EXPORT AudioDecoderOpus {
  struct Config {
    bool IsOk() const;                   // 校验有效性
    int sample_rate_hz = 48000;          // 默认 48kHz
    std::optional<int> num_channels;     // 未设置时由 field trial 决定
  };

  static std::optional<Config> SdpToConfig(const SdpAudioFormat& audio_format);
  static void AppendSupportedDecoders(std::vector<AudioCodecSpec>* specs);

  // V2: 带 Environment 的解码器创建
  static std::unique_ptr<AudioDecoder> MakeAudioDecoder(const Environment& env,
                                                        Config config);
  // V1: 兼容旧接口，转发到 V2
  static std::unique_ptr<AudioDecoder> MakeAudioDecoder(
      const Environment& env,
      Config config,
      std::optional<AudioCodecPairId> /*codec_pair_id*/);
};
```

关键特性：
- `num_channels` 使用 `std::optional<int>`，表示可以不在 Config 中指定，由 `MakeAudioDecoder` 在构造时根据 field trial 决定。
- 两个重载的 `MakeAudioDecoder`：主版本接受 `Environment`，简化版本忽略 `codec_pair_id`。

## 实现文件 (.cc)

**文件**: `api/audio_codecs/opus/audio_decoder_opus.cc`

1. **辅助函数 `GetDefaultNumChannels()`**: 根据 field trial `"WebRTC-Audio-OpusDecodeStereoByDefault"` 决定默认声道数。启用时默认为 2（立体声），否则为 1（单声道）。

2. **`Config::IsOk()`**: 采样率必须为 16000 或 48000 Hz（libopus 支持更多采样率但 WebRTC 目前只启用这两个）。`num_channels` 如果设置，必须是 1 或 2。

3. **`SdpToConfig()`**: 检查 SDP 格式名称是否为 `"opus"`（不区分大小写）、`clockrate_hz == 48000`、`num_channels == 2`。解析 SDP 参数中的 `"stereo"` 参数：`"0"` 设置为单声道，`"1"` 设置为立体声。如果 `"stereo"` 参数格式错误则返回 `std::nullopt`。

4. **`AppendSupportedDecoders()`**: 添加 Opus 标准规格：
   - `AudioCodecInfo`: `{48000, 1, 64000, 6000, 510000}`（1 声道、默认 64kbps、范围 6kbps-510kbps）
   - `allow_comfort_noise = false`: Opus 自带舒适噪声生成，无需外部 CNG。
   - `supports_network_adaption = true`: Opus 支持码率和帧长自适应。
   - SDP 参数: `minptime=10`, `useinbandfec=1`。

5. **`MakeAudioDecoder(env, config)`**: 使用 `config.num_channels.value_or(GetDefaultNumChannels(env.field_trials()))` 决定声道数，然后创建 `AudioDecoderOpusImpl(env.field_trials(), channels, sample_rate_hz)`。

## 学习扩展

- **Field Trial 控制**: `WebRTC-Audio-OpusDecodeStereoByDefault` 字段实验（field trial）允许在不修改代码的情况下控制 Opus 解码器的默认立体声行为，这是 WebRTC 进行 A/B 测试和渐进式功能发布的标准方式。
- **Opus 编码参数**: Opus 的码率范围极广（6kbps-510kbps），能够覆盖从语音（低码率）到高保真音乐（高码率）的所有场景。
- **useinbandfec**: Opus 支持带内 FEC（Forward Error Correction），即在数据包中携带前一帧的低码率副本以提高抗丢包能力。
- **minptime**: 最小包长 10ms，表示 Opus 解码器可以处理 10ms 的音频帧。
- **Environment 机制**: 较新的 codec API 开始接受 `Environment` 对象作为参数，提供 field trials、任务队列等运行时上下文，替代之前分散的参数传递方式。

## 设计模式

- **外观模式 (Facade)**: 封装 Opus 解码器创建过程。
- **可选配置 (Optional Config)**: 使用 `std::optional` 实现灵活配置，`num_channels` 可选，不由 SDP 指定时由 field trial 或默认值决定。
- **版本兼容 (Version Compatibility)**: 提供两个 `MakeAudioDecoder` 重载，旧接口调用新接口，保持向后兼容。
