# enable_media

## 概述

`enable_media.h` / `enable_media.cc` 提供了 `EnableMedia` 函数，用于向 `PeerConnectionFactoryDependencies` 注入默认的媒体引擎支持。这是 WebRTC 模块化设计的关键组件——允许应用程序在不需要音视频媒体时完全避免链接媒体模块，从而减小二进制体积。

在 WebRTC 架构中，该文件位于 `api/` 层，是 `CreatePeerConnectionFactory` 与媒体引擎之间的桥梁。

## 头文件接口 (.h)

### 函数 `EnableMedia`

| 参数 | 类型 | 说明 |
|------|------|------|
| `deps` | `PeerConnectionFactoryDependencies&` | 待填充的依赖结构体 |

函数声明为 `RTC_EXPORT`，但位于独立的 build target 中，以便不需要媒体的用户避免链接媒体代码。

## 实现文件 (.cc)

### MediaFactoryImpl
文件内部定义了一个 `MediaFactoryImpl` 类（继承自 `MediaFactory`），提供两个方法：

1. **`CreateCall(CallConfig)`**：创建 `Call` 实例，这是 WebRTC 内部管理媒体流的核心模块。
2. **`CreateMediaEngine(Environment, PeerConnectionFactoryDependencies&)`**：
   - 使用 `deps.audio_processing_builder->Build(env)` 构建 `AudioProcessing`。
   - 创建 `WebRtcVoiceEngine`（音频引擎），整合 ADM、编解码器工厂、混音器、音频处理等。
   - 创建 `WebRtcVideoEngine`（视频引擎），整合编解码器工厂。
   - 将两个引擎组合为 `CompositeMediaEngine` 返回。

### EnableMedia 函数
```cpp
void EnableMedia(PeerConnectionFactoryDependencies& deps) {
  if (deps.media_factory != nullptr) {
    return;  // 已注入，避免覆盖（如测试用的 mock 实现）
  }
  deps.media_factory = std::make_unique<MediaFactoryImpl>();
}
```

## 学习扩展

- `EnableMedia` 与 `EnableMediaWithDefaults` 的区别：前者仅注入 `MediaFactory`，后者还会填充编解码器、音频处理等默认实现。
- 如果应用程序不需要音视频（仅使用 DataChannel），直接使用 `CreateModularPeerConnectionFactory` 并跳过调用 `EnableMedia` 即可。
- `CompositeMediaEngine` 内部同时持有音频引擎 (`WebRtcVoiceEngine`) 和视频引擎 (`WebRtcVideoEngine`)，对外提供统一接口。

## 设计模式

**模板方法 (Template Method)**：`MediaFactoryImpl` 实现了 `MediaFactory` 接口，定义了创建 `Call` 和 `MediaEngine` 的具体逻辑。

**策略模式 (Strategy)**：`PeerConnectionFactoryDependencies::media_factory` 允许注入不同的 `MediaFactory` 实现，使媒体引擎的创建策略可替换。

**空对象模式 (Null Object)**：通过检查 `deps.media_factory != nullptr` 实现幂等性，已注入时跳过。
