# WebRTC 音频编解码器 API 文档

## 概述

`api/audio_codecs/` 定义了 WebRTC 音频编解码器的公共接口和工厂模式。WebRTC 必须支持 Opus 和 PCM (G.711)，L16 和 G.722 也是常见兼容编解码器。

---

## 一、核心编解码器接口

### audio_encoder.cc
**路径**: `api/audio_codecs/audio_encoder.cc`
**关键类**: `AudioEncoder`, `AudioEncoder::EncodedInfo`, `ANAStats`

音频编码器抽象基类。采用 NVI 模式——公开 `Encode()` 执行参数校验后调用虚函数 `EncodeImpl()`。

**核心方法**:

| 方法 | 说明 |
|------|------|
| `Encode(rtp_timestamp, audio, encoded)` | 编码 PCM → 压缩比特流。校验帧大小必须为 `NumChannels() × SampleRateHz() / 100`（10ms 数据） |
| `SampleRateHz()` | 采样率 (Hz) |
| `NumChannels()` | 声道数 |
| `RtpTimestampRateHz()` | RTP 时间戳频率（默认等于 SampleRateHz） |
| `SetFec(bool)` | 设置 FEC (前向纠错)，默认不支持 |
| `SetDtx(bool)` / `GetDtx()` | 设置/查询 DTX (不连续传输/VAD) |
| `SetTargetBitrate(target_bps)` | 设置目标码率 |
| `EnableAudioNetworkAdaptor(config)` | 启用音频网络自适应 (ANA) |
| `OnReceivedUplinkPacketLossFraction(loss)` | 接收上行丢包率反馈 |
| `OnReceivedTargetAudioBitrate(bitrate)` | 接收上行目标码率 |
| `GetANAStats()` | 获取 ANA 统计信息 |

**`EncodedInfo`** — 编码结果元数据：
- `encoded_bytes` — 编码字节数
- `encoded_timestamp` — 编码后的 RTP 时间戳
- `payload_type` — 负载类型
- `speech` — 是否语音（或 CNG/DTX）
- `send_even_if_empty` — 是否发送空帧（CNG 场景）

**音频网络自适应 (ANA)**: 通过 RTCP 反馈动态调整编码参数（码率、帧长、FEC 量）。

**默认实现**: 多数方法返回 `false` / `nullptr` / 空操作。子类按需覆盖（如 Opus 覆盖几乎所有方法）。

### audio_decoder.cc
**路径**: `api/audio_codecs/audio_decoder.cc`
**关键类**: `AudioDecoder`, `AudioDecoder::ParseResult`

音频解码器抽象基类。

**核心方法**:
- `Decode(rtp_timestamp, encoded, sample_rate_hz, speaker_count, audio)` — 解码
- `DecodePlc(num_frames, audio)` — PLC (Packet Loss Concealment，丢包隐藏)
- `ParsePayload(payload, timestamp)` — 解析 RTP 负载但不解码
- `IncomingPacket(payload, rtp_info)` — 通知解码器收到新包
- `SampleRateHz()` / `NumChannels()` / `PacketDuration()` / `ErrorCode()`

**`ParseResult`**: 区分 `kAdtsHeader` (ADTS 格式头，AAC 场景) 和 `kPayloadSpecificHeader` (编解码器特定头)。

---

## 二、音频格式

### audio_format.cc
**路径**: `api/audio_codecs/audio_format.cc`
**关键类**: `SdpAudioFormat`, `AudioCodecPairId`

`SdpAudioFormat` 描述 SDP 层面的音频编解码器格式：
- `name` — 编解码器名称 ("opus", "PCMU", "PCMA")
- `clockrate_hz` — 时钟频率（通常等于采样率）
- `num_channels` — 声道数
- `parameters` — 编解码器参数 (对应 SDP `a=fmtp:`)

**`IsStatelessCodec()`**: 判断是否为无状态编解码器 (PCMU, PCMA, L16)。无状态编解码器每帧独立解码，不依赖前序帧。

### audio_codec_pair_id.cc
**路径**: `api/audio_codecs/audio_codec_pair_id.cc`

为每个音频编解码器对 (Encoder + Decoder) 分配唯一 ID，用于识别和测试。

---

## 三、编解码器实现 (L16/G711/G722/Opus)

### L16 (16-bit Linear PCM)
**文件**: `L16/audio_encoder_L16.cc`, `L16/audio_decoder_L16.cc`

L16 是未压缩的 16-bit PCM 音频。带宽大但质量无损。主要用于测试和内部场景。

### G.711 (PCM μ-law/A-law)
**文件**: `g711/audio_encoder_g711.cc`, `g711/audio_decoder_g711.cc`

G.711 是 8kHz 采样率的电话语音编解码器：
- **PCMU** (μ-law): 北美/日本标准
- **PCMA** (A-law): 欧洲/国际标准

### G.722 (7kHz Wideband)
**文件**: `g722/audio_encoder_g722.cc`, `g722/audio_decoder_g722.cc`

G.722 是 16kHz 采样率的宽带编解码器。提供 AMR-WB 之外的传统宽带选择。

### Opus
**文件**: `opus/audio_encoder_opus.cc`, `opus/audio_decoder_opus.cc`, `opus/audio_encoder_multi_channel_opus.cc`, `opus/audio_decoder_multi_channel_opus.cc`, `opus/audio_encoder_opus_config.cc`

**Opus 是 WebRTC 的首选音频编解码器**（RFC 6716，强制实现）。

**关键特性**:
- 采样率: 8kHz ~ 48kHz
- 码率范围: 6 kbps ~ 510 kbps
- 低延迟: 2.5ms ~ 60ms 帧长
- 支持 CBR/VBR/CVBR
- 内建 FEC + DTX + VAD
- 支持立体声和多声道 (最多 255 声道)

**编码器配置**: `AudioEncoderOpusConfig`
- `bitrate` — 目标码率
- `complexity` — 计算复杂度 (0-10, 默认 9)
- `dtx_enabled` — DTX 开关
- `fec_enabled` — FEC 开关
- `application` — 应用模式 (VoIP/Audio/RestrictedLowdelay)
- `max_playback_rate_hz` — 最大播放采样率

**多声道 Opus**: `audio_encoder_multi_channel_opus.cc` 使用多个单声道/立体声 Opus 编码器实现多声道编码。

---

## 四、工厂与注册

### builtin_audio_encoder_factory.cc / builtin_audio_decoder_factory.cc
**路径**: `api/audio_codecs/builtin_audio_encoder_factory.cc`, `builtin_audio_decoder_factory.cc`

创建内置编解码器工厂。使用模板工厂 `AudioEncoderFactoryT<T>` 注册所有可用编解码器：Opus, PCMU, PCMA, G.722, L16 等。

### opus_audio_encoder_factory.cc / opus_audio_decoder_factory.cc
**路径**: `api/audio_codecs/opus_audio_encoder_factory.cc`, `opus_audio_decoder_factory.cc`

创建仅支持 Opus 的工厂——当只需要 Opus 时使用。

---

## 学习扩展

### 音频编解码器对比

| 编解码器 | 采样率 | 码率 | 延迟 | 质量 | WebRTC 必需 |
|----------|--------|------|------|------|-------------|
| **Opus** | 8k-48kHz | 6-510k | 2.5-60ms | 极佳 | **是** |
| **G.711** | 8kHz | 64k | <1ms | 一般 | **是** |
| **G.722** | 16kHz | 48-64k | <2ms | 良好 | 否 |
| **L16** | 任意 | 高(未压缩) | <1ms | 无损 | 否 |

### Opus NetEQ 集成

```
RTP包到达 → NetEQ (抖动缓冲+PLC) → AudioDecoder::Decode()
               │
         [丢包处理]
         [加速/减速/PLC]
```

### 音频编码模板工厂模式

```
AudioEncoderFactoryTemplate<T...>
  ├── MakeAudioEncoder(payload_type, format, options)
  │   └── 遍历 T... 找到匹配 format.name 的编码器
  └── GetSupportedEncoders()
      └── 遍历 T... 收集所有支持的格式和能力
```

### 关键设计模式

| 模式 | 出现位置 | 说明 |
|------|----------|------|
| **NVI** | `AudioEncoder::Encode()` | 公开非虚接口，子类实现 `EncodeImpl()` |
| **Template Method** | `AudioDecoder` | 基类定义解码骨架 |
| **Strategy** | `AudioEncoder`/`AudioDecoder` | 不同编解码器可互换 |
| **Abstract Factory** | `AudioEncoderFactory` | 创建匹配的编解码器实例 |
| **Template** | `AudioEncoderFactoryTemplate<T...>` | 编译期编解码器注册 |
| **Null Object** | `AudioEncoder` 默认方法返回 false | 安全的不操作实现 |
