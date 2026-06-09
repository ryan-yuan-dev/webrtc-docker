# builtin_video_encoder_factory

## 概述

`builtin_video_encoder_factory` 提供创建 WebRTC 内置视频编码器工厂的能力。不同于解码器工厂的简单封装，编码器工厂额外包装了 Simulcast（ simulcast）支持——通过 `SimulcastEncoderAdapter` 为所有内置编码器添加多流编码能力。

## 头文件接口 (.h)

**函数声明**：
- `CreateBuiltinVideoEncoderFactory()`：返回 `unique_ptr<VideoEncoderFactory>`，该工厂支持 Simulcast（特别是 VP8）功能。

## 实现文件 (.cc)

**核心类 `BuiltinVideoEncoderFactory`**：
- 内部持有一个 `InternalEncoderFactory` 实例作为实际编码器创建的后端。
- `Create(env, format)`：尝试根据 `SdpVideoFormat` 创建编码器。如果 format 在内部工厂支持列表中，则创建 `SimulcastEncoderAdapter`，它包装了内部编码器并提供 Simulcast 能力。
- `GetSupportedFormats()`：委托给内部工厂。
- `QueryCodecSupport(format, scalability_mode)`：委托给内部工厂。

**SimulcastEncoderAdapter 的 Passthrough 模式**：当不需要 Simulcast 时，适配器以直通模式运行，直接使用单个编码器实例，对上层透明。

## 学习扩展

- Simulcast 是 WebRTC 的关键特性，允许编码器同时输出多个不同分辨率的视频流，供 SFU（Selective Forwarding Unit）根据接收端能力选择性转发。
- `SimulcastEncoderAdapter` 在 `media/engine/simulcast_encoder_adapter.h` 中定义，内部管理多个编码器实例，每个负责一个 Simulcast 流。
- 该工厂通过匿名命名空间隐藏实现类，仅暴露工厂函数，是 C++ 中接口与实现分离的典型做法。

## 设计模式

**装饰器模式**：`SimulcastEncoderAdapter` 装饰内部编码器工厂，在保留原始编码器能力的基础上增加了 Simulcast 功能。内置类 `BuiltinVideoEncoderFactory` 本身也使用了**适配器模式**，将 `InternalEncoderFactory` 适配为公共 `VideoEncoderFactory` 接口并扩展了 Simulcast 支持。
