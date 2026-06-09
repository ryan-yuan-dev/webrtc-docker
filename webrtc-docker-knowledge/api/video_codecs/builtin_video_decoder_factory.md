# builtin_video_decoder_factory

## 概述

`builtin_video_decoder_factory` 提供了一个简单的工厂函数，用于创建 WebRTC 内置视频解码器工厂实例。它是 WebRTC 内部解码器工厂的公共入口点，上层应用通过调用 `CreateBuiltinVideoDecoderFactory()` 获取能够创建所有 WebRTC 内置解码器的工厂对象。

## 头文件接口 (.h)

**函数声明**：
- `CreateBuiltinVideoDecoderFactory()`：返回一个 `unique_ptr<VideoDecoderFactory>`，该工厂能够创建 WebRTC 内置的所有视频解码器（如 VP8、VP9、AV1、H264、H265 等）。

## 实现文件 (.cc)

**实现细节**：
- 函数直接委托给 `InternalDecoderFactory`（定义在 `media/engine/internal_decoder_factory.h`），返回一个 `InternalDecoderFactory` 实例。
- `InternalDecoderFactory` 内部根据编译配置包含相应解码器的创建逻辑。

## 学习扩展

- WebRTC 内置解码器通过 `media/engine/internal_decoder_factory.cc` 实现，会根据编译时注册的编解码器支持情况动态创建对应解码器。
- 外部应用也可以实现自己的 `VideoDecoderFactory` 来替代或扩展内置解码器。

## 设计模式

**工厂方法模式**：单一工厂函数封装了具体解码器工厂的创建逻辑。客户端只需调用无参数的工厂函数即可获得完整功能的内置解码器工厂，无需了解底层实现细节。这种间接层使得 WebRTC 可以在不改变公共 API 的情况下修改内置解码器的实现。
