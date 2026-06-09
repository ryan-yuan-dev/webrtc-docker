# rtp_parameters

## 概述

`rtp_parameters.h` / `rtp_parameters.cc` 定义了 WebRTC 中 RTP 参数体系的完整类型集合，包括 `RtpParameters`、`RtpEncodingParameters`、`RtpCodecParameters`、`RtpCapabilities` 以及相关的辅助类型。这些结构体用于查询和配置 RtpSender 和 RtpReceiver 的参数。

在 WebRTC 架构中，该文件位于 `api/` 层，对应 W3C WebRTC 规范中的 `RTCRtpParameters` 及其子类型。

## 头文件接口 (.h)

### 枚举

**`FecMechanism`**

| 值 | 说明 |
|----|------|
| `RED` | RED (Redundant Encoding) |
| `RED_AND_ULPFEC` | RED + ULPFEC |
| `FLEXFEC` | FlexFEC |

**`RtcpFeedbackType`**

| 值 | 说明 |
|----|------|
| `CCM` | Codec Control Message |
| `LNTF` | Loss Notification |
| `NACK` | Negative ACK |
| `REMB` | Receiver Estimated Max Bitrate |
| `TRANSPORT_CC` | Transport-Wide Congestion Control |
| `CCFB` | Congestion Control Feedback (RFC 8888) |

**`RtcpFeedbackMessageType`**

| 值 | 说明 |
|----|------|
| `GENERIC_NACK` | 通用 NACK |
| `PLI` | 图像丢失指示 (用于 NACK) |
| `FIR` | 全帧内请求 (用于 CCM) |

**`DtxStatus`** / **`DegradationPreference`**

| `DtxStatus` | 说明 |
|-------------|------|
| `DISABLED` | 禁用 DTX |
| `ENABLED` | 启用 DTX |

| `DegradationPreference` | 说明 |
|-------------------------|------|
| `DISABLED` | 不采取降级处理 |
| `MAINTAIN_FRAMERATE` | 降低分辨率保持帧率 |
| `MAINTAIN_RESOLUTION` | 降低帧率保持分辨率 |
| `BALANCED` | 平衡帧率和分辨率 |

### 关键结构体

**`RtcpFeedback`**

| 字段 | 说明 |
|------|------|
| `type` | RTCP 反馈类型 |
| `message_type` | 反馈消息类型 (NACK/CCM 时设置) |

**`RtpCodec`**

| 字段 | 说明 |
|------|------|
| `name` | 编码器名称 (如 VP8, H264, Opus) |
| `kind` | 媒体类型 (Audio/Video) |
| `clock_rate` | 时钟频率 |
| `num_channels` | 音频声道数 |
| `rtcp_feedback` | 支持的 RTCP 反馈机制 |
| `parameters` | 编码器参数 (对应 SDP a=fmtp) |

**`RtpCodecCapability`** (继承自 `RtpCodec`)
添加 `preferred_payload_type`（优先载荷类型）和 `scalability_modes`（可扩展模式列表）。

**`RtpCodecParameters`** (继承自 `RtpCodec`)
添加 `payload_type`（实际使用的载荷类型）。

**`RtpHeaderExtensionCapability`**
描述 RTP 头部扩展的能力：

| 字段 | 说明 |
|------|------|
| `uri` | 扩展 URI (RFC 8285) |
| `preferred_id` | 偏好 ID |
| `preferred_encrypt` | 是否加密 (RFC 6904) |
| `direction` | 扩展方向 (kSendRecv/kSendOnly/kRecvOnly/kStopped) |

**`RtpExtension`**
RTP 头部扩展的具体实例：

| 字段 | 说明 |
|------|------|
| `uri` | 扩展 URI |
| `id` | 扩展 ID |
| `encrypt` | 是否加密 |

此结构体预定义了 20+ 个标准扩展 URI，包括：
- `kAudioLevelUri`：音频电平
- `kAbsSendTimeUri`：绝对发送时间
- `kAbsoluteCaptureTimeUri`：绝对捕获时间
- `kVideoRotationUri`：视频旋转
- `kTransportSequenceNumberUri`：传输序列号
- `kPlayoutDelayUri`：播放延迟
- `kMidUri`：Media ID (RFC 8843)
- `kRidUri` / `kRepairedRidUri`：RTP Stream ID
- `kDependencyDescriptorUri`：依赖描述符 (AV1)

**`RtpFecParameters`** / **`RtpRtxParameters`**
FEC 和 RTX 重传的配置参数。

**`RtpEncodingParameters`**
编码参数（Simulcast/分层编码配置）：

| 字段 | 说明 |
|------|------|
| `ssrc` | SSRC (未设置时由实现选择) |
| `csrcs` | CSRC 列表 |
| `bitrate_priority` | 比特率优先级 (默认 1.0) |
| `network_priority` | DSCP 网络优先级 |
| `max_bitrate_bps` | 最大比特率 |
| `min_bitrate_bps` | 最小比特率 |
| `max_framerate` | 最大帧率 |
| `num_temporal_layers` | 时域层数 |
| `scale_resolution_down_by` | 分辨率缩放因子 |
| `scalability_mode` | 可扩展模式 |
| `scale_resolution_down_to` | 目标分辨率 (替代缩放因子) |
| `active` | 是否编码发送 |
| `rid` | RTP Stream ID |
| `request_key_frame` | 请求关键帧 |
| `adaptive_ptime` | 自适应音频包长 |
| `codec` | 指定编码器 |

**`RtcpParameters`**

| 字段 | 说明 |
|------|------|
| `ssrc` | RTCP 发送方 SSRC |
| `cname` | CNAME (SDES) |
| `reduced_size` | 精简 RTCP |
| `mux` | RTCP Mux |

**`RtpParameters`**

| 字段 | 说明 |
|------|------|
| `transaction_id` | 事务 ID (防止过时参数被应用) |
| `mid` | Media ID |
| `codecs` | 编解码器参数列表 |
| `header_extensions` | RTP 头部扩展列表 |
| `encodings` | 编码参数列表 |
| `rtcp` | RTCP 参数 |
| `degradation_preference` | 降级偏好 |

**`RtpCapabilities`**

| 字段 | 说明 |
|------|------|
| `codecs` | 支持的编解码器能力列表 |
| `header_extensions` | 支持的头部扩展能力列表 |
| `fec` | 支持的 FEC 机制列表 |

### 常量

| 常量 | 值 | 说明 |
|------|-----|------|
| `kDefaultBitratePriority` | `1.0` | 默认比特率优先级 |

## 实现文件 (.cc)

### DegradationPreferenceToString
将枚举映射为字符串：
- `DISABLED` -> `"disabled"`
- `MAINTAIN_FRAMERATE` -> `"maintain-framerate"`
- `MAINTAIN_RESOLUTION` -> `"maintain-resolution"`
- `BALANCED` -> `"balanced"`

### RtpCodec::IsResiliencyCodec / IsMediaCodec
- IsResiliencyCodec：检查名称是否为 `rtx`、`red`、`ulpfec` 或 `flexfec`。
- IsMediaCodec：不是弹性和舒适噪声编码器的视为媒体编解码器。

### RtpExtension::IsSupportedForAudio / IsSupportedForVideo
列出每种媒体类型支持的头部扩展 URI（音频 7+ 个，视频 16+ 个）。

### RtpExtension::IsEncryptionSupported
判断扩展是否支持加密，排除 `kAbsSendTimeUri`（当 `ENABLE_EXTERNAL_AUTH` 时）和 `kEncryptHeaderExtensionsUri`。

### RtpExtension::FindHeaderExtensionByUri
按 URI 和过滤策略查找扩展：
- `kDiscardEncryptedExtension`：仅接受未加密
- `kPreferEncryptedExtension`：优先加密，回退未加密
- `kRequireEncryptedExtension`：仅接受加密

### RtpExtension::DeduplicateHeaderExtensions
去重 + 排序逻辑：
1. 根据 filter 策略，优先保留加密或未加密。
2. 去除 URI 重复的扩展。
3. 按 (URI, encrypt, id) 排序，便于列表比较。

## 学习扩展

- `RtpParameters` 是对 ORTC 规范 `RTCRtpParameters` 的 C++ 实现，结构与 W3C `RTCRtpSender.getParameters()` / `setParameters()` 对应。
- 未设置的 SSRC 被视为"通配符"：实现选择后不会通过 GetParameters 返回，因为可能因冲突而变化。
- `DegradationPreference` 仅适用于视频 Track，音频无此概念。
- Simulcast 场景下，`RtpEncodingParameters` 列表中的每个元素对应一个 Simulcast 层，按质量升序排列。

## 设计模式

**值对象 (Value Object)**：所有参数结构体作为数据容器，提供默认构造和相等比较。

**策略模式 (Strategy)**：`DegradationPreference` 定义了带宽受限时的降级策略。
