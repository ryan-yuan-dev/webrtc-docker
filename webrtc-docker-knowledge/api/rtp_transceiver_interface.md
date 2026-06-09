# rtp_transceiver_interface

## 概述

`rtp_transceiver_interface.h` / `rtp_transceiver_interface.cc` 定义了 `RtpTransceiverInterface` 类和相关的 `RtpTransceiverInit` 结构体。RtpTransceiver 是 Unified Plan SDP 的核心概念，将一个 RtpSender 和一个 RtpReceiver 组合在一起，共享同一个 mid。

在 WebRTC 架构中，该文件位于 `api/` 层，对应 W3C 规范的 `RTCRtpTransceiver` 接口。仅在使用 Unified Plan SDP 语义时可用。

## 头文件接口 (.h)

### 结构体 `RtpTransceiverInit`
用于初始化 RtpTransceiver 的配置：

| 字段 | 类型 | 说明 |
|------|------|------|
| `direction` | `RtpTransceiverDirection` | 初始方向，默认 `kSendRecv` |
| `stream_ids` | `vector<string>` | 关联的 Stream ID 列表 |
| `send_encodings` | `vector<RtpEncodingParameters>` | 初始编码参数（Simulcast 等） |

### 类 `RtpTransceiverInterface`

| 方法 | 说明 |
|------|------|
| `media_type()` | 媒体类型 (Audio/Video) |
| `mid()` | 媒体标识符（协商前为 nullopt） |
| `sender()` | 关联的 RtpSender |
| `receiver()` | 关联的 RtpReceiver |
| `stopped()` | 是否已停止（不能发送/接收） |
| `stopping()` | 是否正在停止（停止已调用但尚未完成） |
| `direction()` | 当前偏好方向 |
| `SetDirection(new_direction)` | (已废弃) 设置方向（无错误返回） |
| `SetDirectionWithError(new_direction)` | 设置方向（带错误返回） |
| `current_direction()` | 当前实际协商的方向（未协商时为 nullopt） |
| `fired_direction()` | 已触发事件的 direction（用于去重事件） |
| `StopStandard()` | 标准停止，等待信令完成 |
| `StopInternal()` | 立即停止，不等待信令 |
| `Stop()` | (已废弃) 调用 StopInternal |
| `SetCodecPreferences(codecs)` | 设置编解码器偏好 |
| `codec_preferences()` | 获取当前的编解码器偏好 |
| `GetHeaderExtensionsToNegotiate()` | 待协商的头部扩展列表 |
| `GetNegotiatedHeaderExtensions()` | 已协商的头部扩展列表 |
| `SetHeaderExtensionsToNegotiate(extensions)` | 设置待协商的头部扩展 |

## 实现文件 (.cc)

### RtpTransceiverInit
默认构造：direction = `kSendRecv`。

### fired_direction
默认返回 `std::nullopt`。用于 Chromium 中记录已触发事件的 direction，防止重复触发 `OnTrack` 事件。

### stopping
默认返回 `false`。仅当 Stop 已调用但尚未完成信令协商时为 true。

### Stop 相关
- `Stop()`：已废弃，委托给 `StopInternal()`。
- `StopStandard()`：默认实现触发 `RTC_DCHECK_NOTREACHED()`。
- `StopInternal()`：默认实现触发 `RTC_DCHECK_NOTREACHED()`。
- `SetDirection()`：已废弃，委托给 `SetDirectionWithError()`。
- `SetDirectionWithError()`：默认实现触发 `RTC_DCHECK_NOTREACHED()`。

## 学习扩展

- RtpTransceiver 是 Unified Plan 的核心抽象，每个 Transceiver 对应 SDP 中的一个 m= section。
- `direction` 值影响 CreateOffer/CreateAnswer 生成的 SDP 方向属性：`kSendRecv` -> `sendrecv`, `kSendOnly` -> `sendonly`, `kRecvOnly` -> `recvonly`, `kInactive` -> `inactive`。
- `current_direction` 只在实际完成 Offer/Answer 交换后才有值。
- 停止 Transceiver 有两种方式：`StopStandard()`（优雅关闭，等待信令）和 `StopInternal()`（立即停止，不依赖信令）。
- `SetCodecPreferences` 允许应用层控制编解码器选择和优先级排序。
- `SetHeaderExtensionsToNegotiate` 是 WebRTC 扩展 API，允许控制 RTP 头部扩展的协商。

## 设计模式

**组合模式 (Composite)**：RtpTransceiver 组合了一个 RtpSender 和一个 RtpReceiver，提供统一管理接口。

**状态模式 (State)**：direction、stopped、stopping 构成的状态集合定义了 Transceiver 的生命周期。

**适配器模式 (Adapter)**：将 W3C RTCRtpTransceiver 概念适配为 C++ 接口，同时维护向后兼容性（通过废弃方法委托实现）。
