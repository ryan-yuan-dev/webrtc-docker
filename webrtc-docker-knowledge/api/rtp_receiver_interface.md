# rtp_receiver_interface

## 概述

`rtp_receiver_interface.h` / `rtp_receiver_interface.cc` 定义了 `RtpReceiverInterface` 及其观察者接口 `RtpReceiverObserverInterface`。RtpReceiver 负责接收远端的媒体流，提供对接收到的媒体轨道及相关参数的访问。

在 WebRTC 架构中，该文件位于 `api/` 层，对应 W3C 规范的 `RTCRtpReceiver` 接口。

## 头文件接口 (.h)

### 类 `RtpReceiverObserverInterface`

| 方法 | 说明 |
|------|------|
| `OnFirstPacketReceived(media_type)` | 首次收到媒体包时调用 |

### 类 `RtpReceiverInterface`

继承自 `RefCountInterface` 和 `FrameTransformerHost`。

| 方法 | 说明 |
|------|------|
| `track()` | 获取接收到的 MediaStreamTrack |
| `dtls_transport()` | 获取关联的 DTLS 传输（可能为 null） |
| `stream_ids()` | 获取关联的远端 Stream ID 列表 |
| `streams()` | (即将废弃) 获取关联的远端 Stream 对象列表 |
| `media_type()` | 媒体类型 (Audio/Video) |
| `id()` | 接收器唯一标识 |
| `GetParameters()` | 获取当前接收参数 |
| `SetParameters(params)` | 设置接收参数（目前不支持更改） |
| `SetObserver(observer)` | 注册观察者 |
| `SetJitterBufferMinimumDelay(delay_seconds)` | 设置抖动缓冲区最小延迟 |
| `GetSources()` | 获取 RTP 源信息列表 |
| `SetFrameDecryptor(decryptor)` | 设置帧解密器 |
| `GetFrameDecryptor()` | 获取帧解密器 |
| `SetFrameTransformer(transformer)` | 设置帧变换器 |

## 实现文件 (.cc)

### 默认实现
- `stream_ids()` 返回空 vector。
- `streams()` 返回空 vector。
- `GetSources()` 返回空 vector。
- `SetFrameDecryptor()` / `GetFrameDecryptor()`：无操作/返回 nullptr。
- `dtls_transport()` 返回 nullptr。
- `SetFrameTransformer()`：空实现（待子类覆盖）。

### 废弃方法
`SetDepacketizerToDecoderFrameTransformer()` 已废弃，新代码应使用 `SetFrameTransformer()`。

## 学习扩展

- RtpReceiver 的关联 Stream 通过 `stream_ids()` 获取字符串 ID 列表，而非通过 `streams()` 获取 `MediaStreamInterface` 对象指针（后者正在被废弃）。
- `SetFrameDecryptor` 提供独立的帧级解密能力，与 SRTP 解密无关。
- `SetJitterBufferMinimumDelay` 允许应用层覆盖 NetEq 的默认抖动缓冲延迟策略。
- `FrameTransformerHost` 的子类化使 RtpReceiver 可以接受帧变换器，在解码前对接收到的编码帧进行变换。

## 设计模式

**接口隔离 (Interface Segregation)**：RtpReceiverInterface 提供精简的 API，将帧解密、帧变换等横切关注点通过单独的接口管理。

**观察者模式 (Observer)**：RtpReceiverObserverInterface 用于首次媒体包到达事件通知。
