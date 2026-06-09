# audio_encoder

## 概述

`AudioEncoder` 是 WebRTC AudioCoding 模块中所有音频编码器的抽象基类。定义了将 PCM 音频输入编码为 RTP 数据包的标准接口。所有具体编码器（Opus、G711、G722、L16/PCM16B 等）都继承自该类。它提供了丰富的回调接口，允许上层应用动态调整编码参数以适应网络条件变化。

## 头文件接口 (.h)

**文件**: `api/audio_codecs/audio_encoder.h`

```cpp
class AudioEncoder {
 public:
  enum class CodecType { kOther, kOpus, kIsac, kPcmA, kPcmU, kG722 };

  struct EncodedInfoLeaf {
    size_t encoded_bytes;
    uint32_t encoded_timestamp;
    int payload_type;
    bool send_even_if_empty;
    bool speech;
    CodecType encoder_type;
  };

  struct EncodedInfo : public EncodedInfoLeaf {
    std::vector<EncodedInfoLeaf> redundant;  // 冗余编码信息
  };

  // --- 基础属性 ---
  virtual int SampleRateHz() const = 0;           // 输入采样率
  virtual size_t NumChannels() const = 0;          // 输入声道数
  virtual int RtpTimestampRateHz() const;          // RTP 时间戳速率

  // --- 帧控制 ---
  virtual size_t Num10MsFramesInNextPacket() const = 0;
  virtual size_t Max10MsFramesInAPacket() const = 0;

  // --- 核心编码接口 ---
  EncodedInfo Encode(uint32_t rtp_timestamp,
                     ArrayView<const int16_t> audio, Buffer* encoded);

  virtual int GetTargetBitrate() const = 0;
  virtual void Reset() = 0;

  // --- 网络适配回调 ---
  virtual bool SetFec(bool enable);
  virtual bool SetDtx(bool enable);
  virtual bool GetDtx() const;
  virtual bool SetApplication(Application application);
  virtual void SetMaxPlaybackRate(int frequency_hz);
  virtual void SetTargetBitrate(int target_bps);       // 废弃
  virtual void OnReceivedTargetAudioBitrate(int target_bps);
  virtual void OnReceivedUplinkBandwidth(int target_audio_bitrate_bps,
                                         std::optional<int64_t> bwe_period_ms);
  virtual void OnReceivedUplinkAllocation(BitrateAllocationUpdate update);
  virtual void OnReceivedRtt(int rtt_ms);
  virtual void OnReceivedOverhead(size_t overhead_bytes_per_packet);
  virtual void SetReceiverFrameLengthRange(int min_frame_length_ms,
                                           int max_frame_length_ms);

  // --- Audio Network Adaptor ---
  virtual bool EnableAudioNetworkAdaptor(absl::string_view config);
  virtual void DisableAudioNetworkAdaptor();
  virtual ANAStats GetANAStats() const;

  // --- 帧长和码率范围 ---
  virtual std::optional<std::pair<TimeDelta, TimeDelta>> GetFrameLengthRange() const = 0;
  virtual std::optional<std::pair<DataRate, DataRate>> GetBitrateRange() const;

  static constexpr int kMaxNumberOfChannels = ...;

 protected:
  virtual EncodedInfo EncodeImpl(uint32_t rtp_timestamp,
                                 ArrayView<const int16_t> audio,
                                 Buffer* encoded) = 0;
};
```

**`ANAStats`** 结构体记录了 Audio Network Adaptation 的各控制器动作计数（bitrate、channel、DTX、FEC、frame length），用于调试和监控。

## 实现文件 (.cc)

**文件**: `api/audio_codecs/audio_encoder.cc`

1. **`Encode()`**: 模板方法。先检查输入音频长度是否符合 `NumChannels() * SampleRateHz() / 100`（即 10ms 块），然后调用 `EncodeImpl()` 执行实际编码，最后验证 `encoded->size()` 增量与 `info.encoded_bytes` 一致。

2. **默认回调实现**:
   - `SetFec(true)` / `SetDtx(true)` 返回 false，表示不支持；`SetFec(false)` / `SetDtx(false)` 返回 true。
   - `GetDtx()` 默认返回 false。
   - `SetApplication` 返回 false。
   - `SetMaxPlaybackRate`、`SetTargetBitrate`、`OnReceivedUplinkBandwidth`、`OnReceivedRtt`、`OnReceivedOverhead`、`SetReceiverFrameLengthRange` 均为空操作。
   - `OnReceivedTargetAudioBitrate` 默认转发给 `OnReceivedUplinkBandwidth`。
   - `OnReceivedUplinkAllocation` 从 `BitrateAllocationUpdate` 中提取 target_bitrate 和 bwe_period，转发给 `OnReceivedUplinkBandwidth`。
   - `ReclaimContainedEncoders()` 返回空数组。
   - `EnableAudioNetworkAdaptor` 返回 false。
   - `GetANAStats()` 返回默认构造的 `ANAStats` 对象。

3. **`RtpTimestampRateHz()`**: 默认返回 `SampleRateHz()`。某些编码器（如 G722）可能需要覆盖此方法，因为其内部采样率与 RTP 时间戳速率不同。

## 学习扩展

- **Audio Network Adaptation (ANA)**: 一种自适应机制，编码器根据网络条件（丢包率、RTT、可用带宽）自动调整编码参数（bitrate、frame length、FEC、DTX）。`GetANAStats()` 返回各控制器的动作计数。
- **冗余编码 (Redundancy)**: `EncodedInfo.redundant` 向量支持在同一个 RTP 包中携带多个时间点的编码数据（如 Opus 的 In-band FEC），提高抗丢包能力。
- **BitrateAllocationUpdate**: 来自带宽估计器的码率分配更新，包含 target_bitrate、link_capacity、bwe_period 等信息。
- **Deprecated 标注**: `SetTargetBitrate` 和 `OnReceivedUplinkRecoverablePacketLossFraction` 已标注 `ABSL_DEPRECATED`，应使用 `OnReceivedTargetAudioBitrate` 和 `OnReceivedUplinkBandwidth` 替代。

## 设计模式

- **模板方法模式 (Template Method)**: `Encode()` 是模板方法，统一检查输入的前置条件和输出的后置条件，将实际编码委托给 `EncodeImpl()`。
- **策略模式 (Strategy)**: 各种网络适配回调（`SetFec`、`SetDtx`、`OnReceivedRtt` 等）构成策略接口，子类选择性地覆盖以实现自适应算法。
- **空对象模式 (Null Object)**: 默认实现为空操作或返回 false，使子类只需覆盖关心的回调。
