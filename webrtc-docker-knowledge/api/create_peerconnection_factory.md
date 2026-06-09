# create_peerconnection_factory

## 概述

`create_peerconnection_factory.h` / `create_peerconnection_factory.cc` 提供了便捷的工厂函数 `CreatePeerConnectionFactory`，用于快速创建 `PeerConnectionFactoryInterface` 实例。它是 `CreateModularPeerConnectionFactory` 的上层便捷包装，为最常见的使用场景提供默认配置。

在 WebRTC 架构中，这是绝大多数应用程序创建 WebRTC 引擎的入口点。

## 头文件接口 (.h)

### 函数 `CreatePeerConnectionFactory`

| 参数 | 类型 | 说明 |
|------|------|------|
| `network_thread` | `Thread*` | 网络线程 |
| `worker_thread` | `Thread*` | 工作线程 |
| `signaling_thread` | `Thread*` | 信令线程 |
| `default_adm` | `scoped_refptr<AudioDeviceModule>` | 音频设备模块 |
| `audio_encoder_factory` | `scoped_refptr<AudioEncoderFactory>` | 音频编码器工厂 |
| `audio_decoder_factory` | `scoped_refptr<AudioDecoderFactory>` | 音频解码器工厂 |
| `video_encoder_factory` | `unique_ptr<VideoEncoderFactory>` | 视频编码器工厂 |
| `video_decoder_factory` | `unique_ptr<VideoDecoderFactory>` | 视频解码器工厂 |
| `audio_mixer` | `scoped_refptr<AudioMixer>` | 音频混音器 |
| `audio_processing` | `scoped_refptr<AudioProcessing>` | 音频处理模块 |
| `audio_frame_processor` | `unique_ptr<AudioFrameProcessor>` (默认 nullptr) | 音频帧处理器 |
| `field_trials` | `unique_ptr<FieldTrialsView>` (默认 nullptr) | Field trials 配置 |

## 实现文件 (.cc)

### 执行流程

1. **创建 `PeerConnectionFactoryDependencies`**：从函数参数中提取所有依赖，填充到结构体中。
2. **创建 RtcEventLogFactory**：自动创建 `RtcEventLogFactory` 实例用于事件日志。
3. **创建 Environment**：如果传入了 `field_trials`，则创建对应的 Environment 对象。
4. **设置 SocketFactory**：如果提供了 network_thread，使用其 `SocketServer()` 作为 socket 工厂。
5. **配置音频处理**：
   - 如果传入了 `audio_processing`，使用 `CustomAudioProcessing` 包装。
   - 否则使用 `BuiltinAudioProcessingBuilder` 创建默认音频处理。
6. **启用媒体**：调用 `EnableMedia(dependencies)`，注入默认的媒体工厂（VoiceEngine + VideoEngine）。
7. **调用下层入口**：最终调用 `CreateModularPeerConnectionFactory(std::move(dependencies))`。

### 依赖链

```
CreatePeerConnectionFactory(...)
  --> 组装 PeerConnectionFactoryDependencies
  --> EnableMedia(deps)  // 注入 media_factory
  --> CreateModularPeerConnectionFactory(deps)
    --> PeerConnectionFactory::Create(deps)
    --> PeerConnectionFactoryProxy::Create(...)
```

## 学习扩展

- 如果应用程序需要完全控制依赖注入（例如自定义网络层、跳过媒体模块），应直接使用 `CreateModularPeerConnectionFactory`。
- `CustomAudioProcessing` 包装允许用户注入自定义的 `AudioProcessing` 实例。
- `RtcEventLogFactory` 自动创建，用于记录 RTP/RTCP 事件日志（调试/分析用）。

## 设计模式

**外观模式 (Facade Pattern)**：对 `CreateModularPeerConnectionFactory` 的简化封装，将复杂的依赖组装逻辑隐藏在简单的函数签名之后。

**链式工厂 (Factory Chain)**：`CreatePeerConnectionFactory` -> `CreateModularPeerConnectionFactory` -> `PeerConnectionFactory::Create`，形成工厂函数链，每一层增加适当粒度的抽象。
