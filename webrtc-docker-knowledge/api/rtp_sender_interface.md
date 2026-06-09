# rtp_sender_interface

## 概述

`rtp_sender_interface.h` / `rtp_sender_interface.cc` 定义了 `RtpSenderInterface` 及其观察者接口 `RtpSenderObserverInterface`。RtpSender 负责将本地媒体流编码并通过网络发送到远端，提供对发送参数、Track 关联和加密能力的完整控制。

在 WebRTC 架构中，该文件位于 `api/` 层，对应 W3C 规范的 `RTCRtpSender` 接口。

## 头文件接口 (.h)

### 类 `RtpSenderObserverInterface`

| 方法 | 说明 |
|------|------|
| `OnFirstPacketSent(media_type)` | 首次媒体包发送时回调 |

### 类型别名

```cpp
using SetParametersCallback = absl::AnyInvocable<void(RTCError) &&>;
```

### 类 `RtpSenderInterface`

继承自 `RefCountInterface` 和 `FrameTransformerHost`。

| 方法 | 说明 |
|------|------|
| `SetTrack(track)` | 设置要发送的 Track（音频/视频类型不匹配时失败） |
| `track()` | 获取当前关联的 Track |
| `dtls_transport()` | 获取 DTLS 传输 |
| `ssrc()` | 获取主要 SSRC (0 表示尚未确定) |
| `media_type()` | 媒体类型 |
| `id()` | 发送器唯一标识 |
| `stream_ids()` | 关联的 Stream ID 列表 |
| `SetStreams(stream_ids)` | 设置关联的 Stream ID |
| `init_send_encodings()` | 获取初始编码参数 |
| `GetParameters()` | 获取当前发送参数 |
| `SetParameters(params)` | 同步设置发送参数 |
| `SetParametersAsync(params, callback)` | 异步设置发送参数 |
| `SetObserver(observer)` | 注册观察者 |
| `GetDtmfSender()` | 获取 DTMF 发送器（视频返回 null） |
| `SetFrameEncryptor(encryptor)` | 设置帧加密器 |
| `GetFrameEncryptor()` | 获取帧加密器 |
| `SetEncoderSelector(selector)` | 设置编码器选择器 |
| `SetFrameTransformer(transformer)` | 设置帧变换器 |

## 实现文件 (.cc)

### SetParametersAsync
```cpp
void RtpSenderInterface::SetParametersAsync(
    const RtpParameters& parameters,
    SetParametersCallback callback) {
  RTC_DCHECK_NOTREACHED() << "Default implementation called";
}
```
默认实现触发 DCHECK 失败，期望子类提供异步实现。

## 学习扩展

- `ssrc()` 返回主发送 SSRC。在 Simulcast 场景中，多个编码参数使用不同的 SSRC，但 `ssrc()` 只返回主 SSRC（通常对应第一层）。
- `init_send_encodings()` 返回传入 `AddTransceiver` 或 `AddTrack` 时的初始编码参数，这些参数在 SDP 协商前设定。
- `SetFrameEncryptor` 提供帧级的加密能力，与 SRTP 加密独立。加密后的帧无法被标准 WebRTC 解密。
- `SetEncoderSelector` 允许注入自定义的编码器选择逻辑（例如在 Simulcast 场景中选择特定编码器）。
- `GetDtmfSender()` 用于发送 DTMF（按键音）信号，仅对音频 Sender 有效。

## 设计模式

**策略模式 (Strategy)**：`SetEncoderSelector` 允许注入不同的编码器选择策略。

**装饰器模式 (Decorator)**：帧加密器和帧变换器作为可选处理步骤添加到发送流水线。

**适配器模式 (Adapter)**：`SetFrameTransformer` 的继承自 `FrameTransformerHost`，将帧变换能力适配到 RtpSender 上。
