# audio_decoder_multi_channel_opus

## 概述

`AudioDecoderMultiChannelOpus` 是 WebRTC 中多声道 Opus 解码器的 API 结构体。支持 5.1 环绕声（6 声道）和 7.1 环绕声（8 声道）等多声道配置。通过 `AudioDecoderMultiChannelOpusConfig` 配置声道映射（channel mapping）。实际解码由 `modules/audio_coding/codecs/opus/audio_decoder_multi_channel_opus_impl.h` 中的 `AudioDecoderMultiChannelOpusImpl` 实现。

## 相关配置 (`audio_decoder_multi_channel_opus_config.h`)

**文件**: `api/audio_codecs/opus/audio_decoder_multi_channel_opus_config.h`

```cpp
struct AudioDecoderMultiChannelOpusConfig {
  int num_channels;
  int num_streams;                        // 编码流数量
  int coupled_streams;                    // 耦合流数量（立体声对）
  std::vector<unsigned char> channel_mapping;  // 声道映射表

  bool IsOk() const;                      // 校验配置有效性
};
```

`IsOk()` 校验：
- `num_channels >= 1` 且 `<= kMaxNumberOfChannels`
- `num_streams >= 0`，`coupled_streams >= 0`
- `num_streams >= coupled_streams`
- `channel_mapping` 长度等于 `num_channels`
- 每个映射值 `<= max_coded_channel`（`num_streams + coupled_streams`），但 `255` 表示该声道被忽略（输出静音）
- 逆映射检查：每个编码声道必须有对应的输入声道（一对一映射）
- `max_coded_channel < 255` 且 `num_channels < 255`

## 头文件接口 (.h)

**文件**: `api/audio_codecs/opus/audio_decoder_multi_channel_opus.h`

```cpp
struct RTC_EXPORT AudioDecoderMultiChannelOpus {
  using Config = AudioDecoderMultiChannelOpusConfig;

  static std::optional<AudioDecoderMultiChannelOpusConfig> SdpToConfig(
      const SdpAudioFormat& audio_format);
  static void AppendSupportedDecoders(std::vector<AudioCodecSpec>* specs);
  static std::unique_ptr<AudioDecoder> MakeAudioDecoder(
      AudioDecoderMultiChannelOpusConfig config,
      std::optional<AudioCodecPairId> codec_pair_id = std::nullopt,
      const FieldTrialsView* field_trials = nullptr);
};
```

## 实现文件 (.cc)

**文件**: `api/audio_codecs/opus/audio_decoder_multi_channel_opus.cc`

1. **`SdpToConfig()`**: 直接委托给 `AudioDecoderMultiChannelOpusImpl::SdpToConfig(format)`。

2. **`AppendSupportedDecoders()`**: 注册两种环绕声配置：
   - **5.1 环绕声** (6 声道):
     - 默认码率 128kbps
     - `channel_mapping = "0,4,1,2,3,5"`
     - `num_streams = 4`, `coupled_streams = 2`
     - `allow_comfort_noise = false`
   - **7.1 环绕声** (8 声道):
     - 默认码率 200kbps
     - `channel_mapping = "0,6,1,2,3,4,5,7"`
     - `num_streams = 5`, `coupled_streams = 3`
     - `allow_comfort_noise = false`

3. **`MakeAudioDecoder()`**: 委托给 `AudioDecoderMultiChannelOpusImpl::MakeAudioDecoder(config)`。

## 学习扩展

- **Opus 多声道原理**: Opus 编解码器通过将多个单声道/立体声流组合来实现多声道。`num_streams` 是编码流总数，`coupled_streams` 是其中的立体声对数，因此总编码声道数为 `num_streams + coupled_streams`。
- **Channel mapping**: `channel_mapping[i]` 表示输入声道 `i` 的数据来自哪个编码声道。值 255 表示该声道无数据（输出静音）。逆映射检查确保了每个编码声道都有唯一的输入来源。
- **LFE (Low Frequency Effects)**: 注释指出代码没有标记 LFE 声道（低频效果声道，即 .1 声道），这是未来的优化方向。
- 此结构体在 `builtin_audio_decoder_factory.cc` 中被 `NotAdvertised<T>` 包装，不向 SDP 广播功能。

## 设计模式

- **外观模式 (Facade)**: 封装多声道 Opus 解码器的创建过程。
- **委托模式 (Delegation)**: 所有静态方法都委托给 `AudioDecoderMultiChannelOpusImpl`（modules 层的真正实现）。
