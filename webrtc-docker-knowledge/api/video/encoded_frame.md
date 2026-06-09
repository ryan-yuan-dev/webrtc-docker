# encoded_frame

## 概述

`EncodedFrame` 是 WebRTC 中表示已编码视频帧的基类，继承自 `EncodedImage`。它扩展了编码图像的功能，增加了帧接收时间、渲染时间、帧 ID、编解码器特定信息、帧间参考关系等字段。该类是视频编解码模块中帧管理体系的核心组件，被 `RtpFrameObject` 等子类继承实现。

## 头文件接口 (.h)

- **继承**：`EncodedFrame` : `EncodedImage`（公开继承）
- **关键常量**：`kMaxFrameReferences = 5`（最大帧参考数量）
- **关键方法**：
  - `ReceivedTime()` / `RenderTime()`：获取接收时间和渲染时间（虚拟方法，可被子类重写）。
  - `ReceivedTimestamp()` / `RenderTimestamp()`：返回 `std::optional<Timestamp>` 类型的包装。
  - `delayed_by_retransmission()`：指示帧是否因重传而延迟。
  - `is_keyframe()`：若 `num_references == 0` 则为关键帧。
  - `Id()` / `SetId()`：帧 ID，用于表示帧的顺序和依赖关系。
  - `PayloadType()`：RTP 负载类型。
  - `CodecSpecific()` / `SetCodecSpecific()`：编解码器特定信息，包括 VP8、VP9、H264 等的具体参数。
  - `SetFrameInstrumentationData()`：设置帧检测数据（用于 corruption detection）。
- **公开成员变量**：
  - `num_references` / `references[]`：帧参考计数和参考帧 ID 数组。
  - `is_last_spatial_layer`：子帧是否为超帧中的最后一个空间层。
- **保护成员**：
  - `_renderTimeMs`、`_payloadType`、`_codecSpecificInfo`、`_codec`。
- **TODO**：注释指出应把 RTP 传输相关信息迁移到传输感知子类（如 `RtpFrameObject`）中。

## 实现文件 (.cc)

- **`ReceivedTimestamp()`**：若 `ReceivedTime() >= 0` 则返回 `Timestamp::Millis(ReceivedTime())`，否则返回 `nullopt`。
- **`RenderTimestamp()`**：类似逻辑处理渲染时间。
- **`delayed_by_retransmission()`**：默认返回 `false`，由子类重写具体逻辑。
- **`CopyCodecSpecific(const RTPVideoHeader* header)`**：核心方法，解析 RTP 头部中的编解码器特定信息并填充 `_codecSpecificInfo`：
  - **VP8**：提取 temporalIdx、layerSync、keyIdx、nonReference 等字段。
  - **VP9**：提取 inter_pic_predicted、flexible_mode、num_ref_pics、temporal_idx、spatial_idx、gof 信息等。
  - **H264**：仅设置 codecType。
  - **AV1**：仅设置 codecType。

## 学习扩展

- 帧 ID 从 RTP 层决定，用于描述帧的解码顺序和依赖关系，是视频编解码参考关系管理的基础。
- 了解 VP8/VP9 的 temporal scalability 层级结构和 GOF（Group of Frames）概念有助于理解 CopyCodecSpecific 中的字段含义。

## 设计模式

**模板方法模式（Template Method）**：`ReceivedTime()` 和 `RenderTime()` 是虚拟方法，子类提供具体实现；`ReceivedTimestamp()` 和 `RenderTimestamp()` 是基于它们的非虚拟包装方法，体现了模板方法的思想。
