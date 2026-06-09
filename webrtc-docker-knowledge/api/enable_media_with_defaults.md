# enable_media_with_defaults

## 概述

`enable_media_with_defaults.h` / `enable_media_with_defaults.cc` 提供了 `EnableMediaWithDefaults` 函数，在 `EnableMedia` 的基础上额外填充默认的编解码器工厂和音频处理构建器，提供即开即用的媒体支持。与 `EnableMedia` 相比，该函数会引入更多的依赖和二进制体积。

在 WebRTC 架构中，这是 `CreatePeerConnectionFactory` 便捷函数内部的组成步骤之一。

## 头文件接口 (.h)

### 函数 `EnableMediaWithDefaults`

| 参数 | 类型 | 说明 |
|------|------|------|
| `deps` | `PeerConnectionFactoryDependencies&` | 待填充的依赖结构体 |

## 实现文件 (.cc)

### 执行逻辑
当 `deps` 中的对应字段为 `nullptr` 时填充默认实现：

```cpp
void EnableMediaWithDefaults(PeerConnectionFactoryDependencies& deps) {
  if (deps.audio_encoder_factory == nullptr)
    deps.audio_encoder_factory = CreateBuiltinAudioEncoderFactory();
  if (deps.audio_decoder_factory == nullptr)
    deps.audio_decoder_factory = CreateBuiltinAudioDecoderFactory();
  if (deps.audio_processing_builder == nullptr)
    deps.audio_processing_builder = make_unique<BuiltinAudioProcessingBuilder>();
  if (deps.video_encoder_factory == nullptr)
    deps.video_encoder_factory = CreateBuiltinVideoEncoderFactory();
  if (deps.video_decoder_factory == nullptr)
    deps.video_decoder_factory = CreateBuiltinVideoDecoderFactory();
  EnableMedia(deps);
}
```

填充的五项默认依赖：

| 依赖项 | 默认实现 |
|--------|----------|
| 音频编码器工厂 | `BuiltinAudioEncoderFactory` |
| 音频解码器工厂 | `BuiltinAudioDecoderFactory` |
| 音频处理构建器 | `BuiltinAudioProcessingBuilder` |
| 视频编码器工厂 | `BuiltinVideoEncoderFactory` |
| 视频解码器工厂 | `BuiltinVideoDecoderFactory` |

## 学习扩展

- 内置编解码器工厂包含常用的音频编解码器（Opus、PCMU/PCMA、G722、iLBC、iSAC）和视频编解码器（VP8、VP9、H264、AV1）。
- 使用 `EnableMediaWithDefaults` 而非 `EnableMedia` 会因为需要链接众多编解码器而显著增加二进制大小。
- `CreatePeerConnectionFactory` 的内部实现直接使用 `EnableMedia` 而非 `EnableMediaWithDefaults`，编解码器由参数传入。

## 设计模式

**策略模式 (Strategy)**：通过预先检查 nullptr 来决定是否注入默认值，允许应用程序优先使用自定义实现。

**空对象模式 (Null Object) 变体**：将 nullptr 视为"未设置"，触发默认行为的填充。
