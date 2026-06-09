# frame_transformer_factory

## 概述

`frame_transformer_factory.h` / `frame_transformer_factory.cc` 提供了实验性的帧克隆工厂函数，用于创建或克隆 `TransformableVideoFrameInterface` 和 `TransformableAudioFrameInterface` 实例。这些函数为 JavaScript 层操作编码后的帧（通过 Insertable Streams API）提供支持。

在 WebRTC 架构中，该文件位于 `api/` 层，是帧变换（Frame Transformer）体系的一部分。

## 头文件接口 (.h)

### 函数列表

| 函数 | 返回类型 | 说明 |
|------|----------|------|
| `CreateVideoSenderFrame()` | `unique_ptr<TransformableVideoFrameInterface>` | (未实现) 创建视频发送帧 |
| `CreateVideoReceiverFrame()` | `unique_ptr<TransformableVideoFrameInterface>` | (未实现) 创建视频接收帧 |
| `CloneAudioFrame(original)` | `unique_ptr<TransformableAudioFrameInterface>` | 克隆音频帧，保留元数据 |
| `CloneVideoFrame(original)` | `unique_ptr<TransformableVideoFrameInterface>` | 克隆视频帧（目前仅支持 sender 帧克隆） |

## 实现文件 (.cc)

### 实现说明
- `CreateVideoSenderFrame()` 和 `CreateVideoReceiverFrame()` 均标记为 `RTC_CHECK_NOTREACHED()`，尚未有实际实现。
- `CloneAudioFrame()`：根据帧的方向（`kReceiver` 或 `kSender`）分别调用 `CloneReceiverAudioFrame()` 或 `CloneSenderAudioFrame()`，实现在对应 delegate 文件中。
- `CloneVideoFrame()`：目前只支持克隆 sender 帧（实际调用 `CloneSenderVideoFrame()`），不支持从 receiver 帧创建 sender 帧。

## 学习扩展

- 帧变换机制是 WebRTC Insertable Streams (aka. 编码流) API 的底层实现，允许 Web 应用在编码后和解码前对音视频帧进行 JavaScript 处理。
- 克隆功能的主要用例是将收到的帧重新发送（例如在 MCU 或 SFU 实现中）。
- 内部实现在 `audio/` 和 `modules/rtp_rtcp/source/` 目录下的 delegate 文件中。

## 设计模式

**工厂方法 (Factory Method)**：提供静态工厂函数用于创建和克隆帧对象。

**原型模式 (Prototype)**：`CloneAudioFrame` / `CloneVideoFrame` 基于已有帧创建新的副本。
