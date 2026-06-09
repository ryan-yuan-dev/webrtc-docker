# frame_transformer_interface

## 概述

`frame_transformer_interface.h` / `frame_transformer_interface.cc` 定义了帧变换（Frame Transformer）系统的核心接口，包括可变换帧、帧变换器、帧变换回调以及帧变换主机接口。该机制允许在编码前或解码后对音视频帧进行自定义处理。

在 WebRTC 架构中，该文件位于 `api/` 层，是 WebRTC Insertable Streams 能力的底层 C++ 接口。

## 头文件接口 (.h)

### 类 `TransformableFrameInterface`
可变换帧的基类接口，表示一个编码后的帧：

| 方法 | 说明 |
|------|------|
| `GetData()` | 获取帧载荷数据（只读到下次非常量调用） |
| `SetData(data)` | 设置新的帧载荷数据 |
| `GetPayloadType()` | RTP 载荷类型 |
| `CanSetPayloadType()` / `SetPayloadType()` | 是否允许修改载荷类型 |
| `GetSsrc()` | 同步源标识符 (SSRC) |
| `GetTimestamp()` | RTP 时间戳 |
| `SetRTPTimestamp(timestamp)` | 设置 RTP 时间戳 |
| `GetPresentationTimestamp()` | 获取呈现时间戳（NTP 时钟域，用于发送方） |
| `GetDirection()` | 帧方向：kReceiver（接收）、kSender（发送）、kUnknown |
| `GetMimeType()` | MIME 类型（如 "video/VP8"） |
| `ReceiveTime()` | 首次在网络接口看到该包的时间（仅接收帧） |
| `CaptureTime()` | 帧捕获时间 |
| `SenderCaptureTimeOffset()` | 发送方与捕获方的时钟偏移 |

### 类 `TransformableVideoFrameInterface`
视频帧接口，继承自 `TransformableFrameInterface`：

| 方法 | 说明 |
|------|------|
| `IsKeyFrame()` | 是否为关键帧 |
| `Metadata()` | 获取视频帧元数据 |
| `SetMetadata()` | 设置视频帧元数据 |

### 类 `TransformableAudioFrameInterface`
音频帧接口，继承自 `TransformableFrameInterface`：

| 方法 | 说明 |
|------|------|
| `GetContributingSources()` | CSRC 列表 |
| `SequenceNumber()` | RTP 序列号 |
| `AbsoluteCaptureTimestamp()` | (将被删除) 绝对捕获时间戳 |
| `Type()` | 帧类型（空帧、语音、CNG） |
| `AudioLevel()` | 音频电平 (-dBov, 0~127) |

### 类 `TransformedFrameCallback`
接收变换后帧的回调接口：

| 方法 | 说明 |
|------|------|
| `OnTransformedFrame(unique_ptr<TransformableFrameInterface>)` | 接收变换后的帧 |
| `StartShortCircuiting()` | 请求直接回调以跳过额外处理 |

### 类 `FrameTransformerInterface`
帧变换器接口，实现自定义帧处理逻辑：

| 方法 | 说明 |
|------|------|
| `Transform(unique_ptr<TransformableFrameInterface>)` | 对帧进行变换处理 |
| `RegisterTransformedFrameCallback(callback)` | 注册接收变换结果的回调 |
| `RegisterTransformedFrameSinkCallback(callback, ssrc)` | 按 SSRC 注册接收回调 |
| `UnregisterTransformedFrameCallback()` | 注销回调 |
| `UnregisterTransformedFrameSinkCallback(ssrc)` | 按 SSRC 注销回调 |

### 类 `FrameTransformerHost`
可托管帧变换器的宿主接口：

| 方法 | 说明 |
|------|------|
| `SetFrameTransformer(transformer)` | 设置帧变换器 |
| 待扩展：`AddIncomingMediaType` / `AddOutgoingMediaType` | |

### Passkey 机制
`TransformableFrameInterface::Passkey` 是一个受限制的 Key 类，仅允许内部已知的帧实现类（如 `TransformableVideoSenderFrame` 等）构造 `TransformableFrameInterface`。这是 C++ 中模拟 sealed class 的惯用模式。

## 实现文件 (.cc)

构造函数实现：
- `TransformableFrameInterface(Passkey)`：空实现，仅通过编译期 Access Control 确保扩展受限。
- `TransformableVideoFrameInterface(Passkey)` 和 `TransformableAudioFrameInterface(Passkey)` 转发给基类。

## 学习扩展

- Frame Transformer 是 WebRTC Insertable Streams (WICG) 的底层能力，在 Chrome 中对应 `RTCRtpScriptTransform`。
- 变换流程：编码器 → (可选的帧变换器) → RTP 打包 → 网络 → RTP 解包 → (可选的帧变换器) → 解码器。
- `Direction` 枚举区分接收帧和发送帧，但官方计划未来移除这个区别，使接收帧可以直接重新发送。
- `Passkey` 模式限制仅有特定内部类可以继承 `TransformableFrameInterface`，保持类层次结构的可控性。

## 设计模式

**策略模式 (Strategy)**：`FrameTransformerInterface` 允许注入不同的帧处理策略。

**回调模式 (Callback)**：`TransformedFrameCallback` 将变换结果返回给调用方。

**Passkey Idiom (Keyed Access)**：通过 `Passkey` 类限制接口的可继承性，实现类似 `final` 的效果。

**职责链 (Chain of Responsibility)**：帧在编码器、变换器、打包器之间传递，形成处理链。
