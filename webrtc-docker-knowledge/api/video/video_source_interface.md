# video_source_interface

## 概述

`VideoSourceInterface` 和 `VideoSinkWants` 是 WebRTC 中视频源-汇（Source-Sink）连接机制的核心组件。`VideoSourceInterface` 是视频源的抽象接口，汇通过 `AddOrUpdateSink()` 注册自身和其偏好（`VideoSinkWants`），源据此调整输出帧的属性。`VideoSinkWants` 结构体描述了汇端对帧分辨率、帧率、旋转对齐等方面的具体要求。

## 头文件接口 (.h)

- **`VideoSinkWants`**：
  - `rotation_applied`：是否希望源应用旋转（默认 false，由汇处理）。
  - `black_frames`：是否只接收黑帧。
  - `max_pixel_count` / `target_pixel_count`：最大和期望像素数。
  - `max_framerate_fps`：最大帧率。
  - `resolution_alignment`：分辨率对齐需求（如 I420 需为 2 的倍数）。
  - `resolutions`：汇配置的分辨率列表（如编码器配置的多分辨率）。
  - `requested_resolution`：用户通过 `RtpEncodingParameters` 请求的分辨率。
  - `is_active`：汇是否活跃（活跃编码器 vs 被动渲染器）。
  - `Aggregates` 子结构：`VideoBroadcaster` 聚合多个 sink 的计算结果，包括 `any_active_without_requested_resolution`。
- **`VideoSourceInterface<VideoFrameT>`**：
  - `AddOrUpdateSink(sink, wants)`：注册或更新汇和其偏好。
  - `RemoveSink(sink)`：移除汇。需保证调用返回后不再有 `OnFrame` 调用。
  - `RequestRefreshFrame()`：请求源捕获新一帧（可选实现）。

## 实现文件 (.cc)

- `VideoSinkWants` 的默认构造、拷贝构造和析构均为 `= default`。

## 学习扩展

- **VideoSinkWants 是自适应的反馈通道**：在 `VideoBroadcaster` 中，多个 sink 的 wants 会被聚合，然后传送给 `AdaptedVideoTrackSource`。后者通过 `VideoAdapter` 根据 wants 计算出最合适的输出分辨率。
- `resolution_alignment` 与 `scaleResolutionDownBy` 的关系：编码器配置的 `scaleResolutionDownBy` 可能需要特定对齐（如某些编码器要求分辨率是 16 的倍数），`resolution_alignment` 确保了帧分辨率满足编码器对齐要求。
- `is_active` 的引入使得视频源可以区分主动编码的编码器和被动的渲染器，避免编码器不活跃时错误地降低采集分辨率。

## 设计模式

**观察者模式（Observer）**：`VideoSourceInterface` 是主题（Subject），`VideoSinkInterface` 是观察者（Observer）。源通过 `AddOrUpdateSink` / `RemoveSink` 管理观察者，并通过 `VideoFrame` 通知观察者。`VideoSinkWants` 实现了**反向控制（Reverse Control）**，让观察者可以向主题反馈其偏好。
