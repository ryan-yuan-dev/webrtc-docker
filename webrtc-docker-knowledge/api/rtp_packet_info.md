# rtp_packet_info

## 概述

`rtp_packet_info.h` / `rtp_packet_info.cc` 定义了 `RtpPacketInfo` 类，用于在接收到的 RTP 包的生命周期内携带每包信息。该结构体主要被 `SourceTracker` 使用，追踪音频/视频源的贡献信息。

在 WebRTC 架构中，该文件位于 `api/` 层，是 RTP 接收流程中信息传递的主要载体之一。

## 头文件接口 (.h)

### 类 `RtpPacketInfo`

| 字段 | 类型 | 说明 |
|------|------|------|
| `ssrc` | `uint32_t` | 同步源标识 (RTP Header) |
| `csrcs` | `vector<uint32_t>` | 贡献源列表 (RTP Header) |
| `rtp_timestamp` | `uint32_t` | RTP 时间戳 (RTP Header) |
| `receive_time` | `Timestamp` | 本地时钟接收时间 |
| `audio_level` | `optional<uint8_t>` | 音频电平 (Audio Level 扩展, RFC 6464) |
| `absolute_capture_time` | `optional<AbsoluteCaptureTime>` | 绝对捕获时间扩展 |
| `local_capture_clock_offset` | `optional<TimeDelta>` | 本地时钟与捕获者时钟的偏移 |

### 构造函数

| 构造函数 | 说明 |
|----------|------|
| `RtpPacketInfo()` | 默认构造 (ssrc=0, receive_time=MinusInfinity) |
| `RtpPacketInfo(ssrc, csrcs, timestamp, receive_time)` | 使用指定参数构造 |
| `RtpPacketInfo(RTPHeader, receive_time)` | 从 RTPHeader 提取信息构造 |

## 实现文件 (.cc)

### 从 RTPHeader 构造
```cpp
RtpPacketInfo::RtpPacketInfo(const RTPHeader& rtp_header, Timestamp receive_time)
    : ssrc_(rtp_header.ssrc),
      rtp_timestamp_(rtp_header.timestamp),
      receive_time_(receive_time) {
  // 提取 CSRCs
  const auto csrcs_count = std::min<size_t>(rtp_header.numCSRCs, kRtpCsrcSize);
  csrcs_.assign(&rtp_header.arrOfCSRCs[0], &rtp_header.arrOfCSRCs[csrcs_count]);

  // 提取 Audio Level
  if (extension.audio_level()) {
    audio_level_ = extension.audio_level()->level();
  }

  // 提取 Absolute Capture Time
  absolute_capture_time_ = extension.absolute_capture_time;
}
```

### 相等性比较
`operator==` 比较所有 7 个字段是否全部相等。

## 学习扩展

- `local_capture_clock_offset` 是 `AbsoluteCaptureTime::estimated_capture_clock_offset` 不同：前者是本地与捕获者的偏移，后者是远程发送方与捕获者的偏移。两者关系：`Capture's NTP Clock = Local NTP Clock + Local-Capture Clock Offset`。
- `RtpPacketInfo` 作为数据传递的中间结构，接收时创建，传递给 `SourceTracker` 后使用。
- `receive_time` 默认值为 `Timestamp::MinusInfinity()`，表示未设置的时间戳。

## 设计模式

**数据传输对象 (DTO)**：`RtpPacketInfo` 作为纯粹的数据载体，在 RTP 接收流程的不同阶段传递每包元数据。
