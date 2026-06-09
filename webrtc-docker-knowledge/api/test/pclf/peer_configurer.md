# peer_configurer

## 概述

`PeerConfigurer` 是 PeerConnection 端到端测试中用于配置单个对端（Peer）的参数设置器。它封装了`PeerConnectionFactoryInterface` 和 `PeerConnectionInterface` 的所有可配置选项，并通过 Builder 模式提供链式 API。

## 头文件接口 (.h)

### `PeerConfigurer` 类

**`VideoSource` 类型**: `variant<unique_ptr<FrameGeneratorInterface>, CapturingDeviceIndex>`

**构造**: `PeerConfigurer(PeerNetworkDependencies& network)`

**PeerConnectionFactory 配置**（通过 `Set` 前缀方法）：

| 方法 | 说明 |
|------|------|
| `SetEventLogFactory()` | 设置事件日志工厂 |
| `SetFecControllerFactory()` | 设置 FEC 控制器工厂 |
| `SetNetworkControllerFactory()` | 设置网络控制器工厂 |
| `SetVideoEncoderFactory()` / `SetVideoDecoderFactory()` | 设置视频编码器/解码器工厂 |
| `SetAudioEncoderFactory()` / `SetAudioDecoderFactory()` | 设置音频编码器/解码器工厂 |
| `SetNetEqFactory()` | 设置 NetEq 工厂 |
| `SetAudioProcessing()` | 设置音频处理构建器 |
| `SetAudioMixer()` | 设置音频混合器 |
| `SetUseNetworkThreadAsWorkerThread()` | 使用网络线程作为工作线程 |

**PeerConnection 配置**：

| 方法 | 说明 |
|------|------|
| `SetAsyncDnsResolverFactory()` | DNS 解析器工厂 |
| `SetRTCCertificateGenerator()` | 证书生成器 |
| `SetSSLCertificateVerifier()` | TLS 证书验证器 |
| `SetIceTransportFactory()` | ICE 传输工厂 |
| `SetPortAllocatorExtraFlags()` | 端口分配器额外标志 |
| `SetPortAllocatorFlags()` | 端口分配器标志（覆盖默认） |

**媒体流配置**：

| 方法 | 说明 |
|------|------|
| `AddVideoConfig(config)` | 添加视频流（默认帧生成器） |
| `AddVideoConfig(config, generator)` | 添加视频流（自定义帧生成器） |
| `AddVideoConfig(config, capturing_device_index)` | 添加视频流（使用摄像头） |
| `SetVideoSubscription(subscription)` | 设置视频订阅 |
| `SetVideoCodecs(codecs)` | 设置视频编解码器列表 |
| `SetExtraVideoRtpHeaderExtensions()` | 设置额外视频 RTP 头扩展 |
| `SetAudioConfig(config)` | 设置音频流 |
| `SetExtraAudioRtpHeaderExtensions()` | 设置额外音频 RTP 头扩展 |

**FEC/编码配置**：

| 方法 | 说明 |
|------|------|
| `SetUseUlpFEC(bool)` | 启用 ULP FEC |
| `SetUseFlexFEC(bool)` | 启用 Flex FEC（同时设置 field trials） |
| `SetVideoEncoderBitrateMultiplier(multiplier)` | 编码器码率倍率 |

**日志/路径**：

| 方法 | 说明 |
|------|------|
| `SetRtcEventLogPath(path)` | 事件日志路径 |
| `SetAecDumpPath(path)` | AEC dump 路径 |

**PeerConnection 选项**：

| 方法 | 说明 |
|------|------|
| `SetPCFOptions(options)` | PeerConnectionFactory 选项 |
| `SetRTCConfiguration(config)` | RTC 配置 |
| `SetRTCOfferAnswerOptions(options)` | Offer/Answer 选项 |
| `SetBitrateSettings(settings)` | 码率设置 |
| `AddFieldTrials(field_trials)` | 追加 field trials |

**释放方法**（调用后转移所有权，仅可调用一次）：
- `ReleaseComponents()` — 释放 `InjectableComponents`
- `ReleaseParams()` — 释放 `Params`
- `ReleaseConfigurableParams()` — 释放 `ConfigurableParams`
- `ReleaseVideoSources()` — 释放视频源

## 实现文件 (.cc)

- 构造函数创建 `InjectableComponents`、`Params`、`ConfigurableParams`，初始化 field trials。
- 所有 `Set*` 方法返回 `this` 指针，支持链式调用。
- `AddVideoConfig(config)` 默认创建 `SquareFrameGenerator`。
- `SetUseFlexFEC()` 同时设置两个 field trials: `WebRTC-FlexFEC-03-Advertised` 和 `WebRTC-FlexFEC-03`。
- `SetPortAllocatorExtraFlags()` 在默认标志基础上增加自定义标志。
- `Release*` 方法通过 `RTC_CHECK` 确保仅释放一次。

## 学习扩展

- **InjectableComponents**: WebRTC 测试框架中可注入的 PeerConnectionFactory 和 PeerConnection 依赖项。
- **Params**: 配置参数集合，包括编解码器、码率、FEC 等。
- **ConfigurableParams**: 测试运行时可调整的参数，如视频流配置、订阅信息等。
- **Flex FEC**: Google 开发的前向纠错方案，与 ULP FEC 不同。

## 设计模式

- **Builder 模式** — 所有 `Set*` 方法返回 `this`，链式调用构建复杂配置。
- **单一责任原则** — `PeerConfigurer` 专注于收集和验证配置。
- **转移语义** — `Release*` 方法通过 unique_ptr 转移所有权。
