# rtp_headers

## 概述

`rtp_headers.h` / `rtp_headers.cc` 定义了 WebRTC 中 RTP/RTCP 头部相关的核心数据结构，包括 `RTPHeader`、`RTPHeaderExtension`、`AbsoluteCaptureTime`、`AudioLevel` 等结构体。这些类型是 RTP 打包/解包过程中的通用数据表示。

在 WebRTC 架构中，该文件位于 `api/` 层，被几乎所有需要处理 RTP 包逻辑的模块引用。

## 头文件接口 (.h)

### 结构体 `FeedbackRequest`
用于 Transport-Wide Congestion Control 的反馈请求：

| 字段 | 说明 |
|------|------|
| `include_timestamps` | 是否包含接收延时信息 |
| `sequence_count` | 反馈覆盖的包数量（0 表示不发反馈） |

### 结构体 `AbsoluteCaptureTime`
绝对捕获时间扩展（用于音视频同步）：

| 字段 | 说明 |
|------|------|
| `absolute_capture_timestamp` | NTP 格式的绝对捕获时间戳 (UQ32.32) |
| `estimated_capture_clock_offset` | 发送方与捕获方 NTP 时钟的估计偏移 |

### 类 `AudioLevel`
音频电平扩展（RFC 6464）：

| 方法 | 说明 |
|------|------|
| `voice_activity()` | 语音活动标志 |
| `level()` | 音频电平 (-dBov, 0~127, 127=静音) |

### 结构体 `RTPHeaderExtension`
RTP 头部扩展字段集合：

| 字段 | 类型 | 说明 |
|------|------|------|
| `hasTransmissionTimeOffset` | `bool` | 是否存在传输时间偏移 |
| `transmissionTimeOffset` | `int32_t` | RTP 时间戳偏移 (RFC 5450) |
| `hasAbsoluteSendTime` | `bool` | 是否存在绝对发送时间 |
| `absoluteSendTime` | `uint32_t` | 24-bit 绝对发送时间 |
| `absolute_capture_time` | `optional<AbsoluteCaptureTime>` | 绝对捕获时间 |
| `hasTransportSequenceNumber` | `bool` | 是否存在传输序列号 |
| `transportSequenceNumber` | `uint16_t` | 传输序列号 (用于带宽估计) |
| `feedback_request` | `optional<FeedbackRequest>` | 拥塞控制反馈请求 |
| `hasVideoRotation` | `bool` | 是否存在视频旋转角度 |
| `videoRotation` | `VideoRotation` | 视频旋转角度 |
| `hasVideoContentType` | `bool` | 是否存在视频内容类型 |
| `videoContentType` | `VideoContentType` | 视频内容类型 |
| `has_video_timing` | `bool` | 是否存在视频时序信息 |
| `video_timing` | `VideoSendTiming` | 视频发送时序 |
| `playout_delay` | `VideoPlayoutDelay` | 播放延迟 |
| `stream_id` | `string` | 流 ID (RFC 8852) |
| `repaired_stream_id` | `string` | 修复流 ID |
| `mid` | `string` | Media ID (RFC 8843) |
| `color_space` | `optional<ColorSpace>` | 色彩空间信息 |
| `audio_level()` | `optional<AudioLevel>` | 音频电平（通过 getter/setter 访问） |

### `GetAbsoluteSendTimestamp()`
将 24-bit 绝对发送时间转换为 `Timestamp` 类型：
```
Timestamp = absoluteSendTime * 1000000 / (1 << 18) microseconds
```

### 结构体 `RTPHeader`
RTP 包头部（RFC 3550）：

| 字段 | 说明 |
|------|------|
| `markerBit` | Marker 位 (M bit) |
| `payloadType` | 载荷类型 (PT, 7 bits) |
| `sequenceNumber` | 序列号 (16 bits) |
| `timestamp` | 时间戳 (32 bits) |
| `ssrc` | 同步源标识符 (32 bits) |
| `numCSRCs` | CSRC 数量 |
| `arrOfCSRCs[15]` | CSRC 贡献源列表 (最多 15 个) |
| `paddingLength` | 填充长度 |
| `headerLength` | 头部总长度 |
| `extension` | `RTPHeaderExtension` 扩展字段 |

### 枚举 `RtcpMode`

| 值 | 说明 |
|----|------|
| `kOff` | 禁用 RTCP |
| `kCompound` | 复合 RTCP (RFC 4585) |
| `kReducedSize` | 精简 RTCP (RFC 5506) |

### 常量

| 常量 | 值 | 说明 |
|------|-----|------|
| `kRtpCsrcSize` | 15 | CSRC 列表最大长度 (RFC 3550) |

## 实现文件 (.cc)

### AudioLevel
- 默认构造：`voice_activity = false`, `audio_level = 0`。
- 带参构造：`RTC_CHECK` 验证 `audio_level` 在 0~127 范围内。

### RTPHeaderExtension
默认构造初始化所有标志位为 `false`，数值为 `0`。

### RTPHeader
默认构造初始化所有字段为默认值，`arrOfCSRCs` 为零初始化。

## 学习扩展

- `RTPHeaderExtension` 的 `absolute_capture_time` 是实现音视频同步的关键，它提供了一个与 NTP 时钟对齐的时间基准。
- `transportSequenceNumber` 结合 `feedback_request` 是实现 Transport-Wide Congestion Control (TWCC) 的基础。
- `mid` 扩展（RFC 8843）在 BUNDLE 机制中用于识别 RTP 包属于哪个 m= section。
- `RTPHeaderExtension` 中的 `audio_level_` 以 private 成员 + getter/setter 形式提供，与其他 public 字段风格不同，这是为了将来迁移到 `std::optional` 做准备。

## 设计模式

****值对象 (Value Object)**：所有结构体都是简单的值类型，提供默认和拷贝构造函数，用于在模块之间传递 RTP 头部信息。
