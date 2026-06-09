# builtin_video_bitrate_allocator_factory

## 概述

`BuiltinVideoBitrateAllocatorFactory` 是 WebRTC 内置的视频码率分配器工厂，实现了 `VideoBitrateAllocatorFactory` 接口。该工厂根据编解码器类型自动选择合适的码率分配策略：对 VP9 和 AV1（非 Simulcast 场景）使用 `SvcRateAllocator`，对其他编解码器使用 `SimulcastRateAllocator`。外部调用者通过 `CreateBuiltinVideoBitrateAllocatorFactory()` 工厂函数获取实例，无需关心底层分配器的创建细节。

## 头文件接口 (.h)

- **函数**：`std::unique_ptr<VideoBitrateAllocatorFactory> CreateBuiltinVideoBitrateAllocatorFactory()`
- 位于 `webrtc` 命名空间下，是唯一的公开入口点。

## 实现文件 (.cc)

- **内部类 `BuiltinVideoBitrateAllocatorFactory`**：继承 `VideoBitrateAllocatorFactory`，实现 `Create()` 方法。
  - `Create(const Environment& env, const VideoCodec& codec)` 方法根据 `codec.codecType` 分发：
    - 对 `kVideoCodecAV1` 或 `kVideoCodecVP9`，且 `numberOfSimulcastStreams <= 1`，创建 `SvcRateAllocator`。
    - 其他情况（包括 H264、VP8、Generic 等）创建 `SimulcastRateAllocator`。
- **工厂函数**：`CreateBuiltinVideoBitrateAllocatorFactory()` 直接返回 `BuiltinVideoBitrateAllocatorFactory` 实例。

## 学习扩展

- **SVC vs Simulcast**：SvcRateAllocator 面向空间/时间可伸缩编码（SVC）场景，适用于 VP9/AV1 的单流模式。SimulcastRateAllocator 面向多码流独立编码（Simulcast）场景。
- 当前代码中存在 TODO 注释，计划未来让 SvcRateAllocator 也支持 Simulcast，统一 VP9/AV1 的码率分配逻辑。

## 设计模式

**工厂方法模式（Factory Method）**：通过静态函数创建分配器工厂对象，工厂内部再根据编解码器类型创建具体的码率分配器。此模式将对象创建与使用解耦，支持未来扩展新的编解码器类型而无需修改客户端代码。
