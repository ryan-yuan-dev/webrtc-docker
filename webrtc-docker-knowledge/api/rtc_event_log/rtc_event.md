# rtc_event

## 概述

`rtc_event` 定义了 RTC 事件日志的基类 `RtcEvent`。该类是所有可记录事件的抽象基类，通过多态机制允许不同类型的 RTC 事件存储在同一缓冲区中。这种设计防止了模块间的依赖泄露——只有某个事件的模块不需要了解其他事件的细节。

## 头文件接口 (.h)

### `RtcEvent` 类

**事件类型枚举 `RtcEvent::Type`**：

| 事件类型 | 说明 |
|---------|------|
| `AlrStateEvent` | 应用限制区域（ALR）状态改变 |
| `RouteChangeEvent` | 路由改变 |
| `RemoteEstimateEvent` | 远端带宽估计 |
| `AudioNetworkAdaptation` | 音频网络自适应 |
| `AudioPlayout` | 音频播放 |
| `AudioReceiveStreamConfig` / `AudioSendStreamConfig` | 音频流配置 |
| `BweUpdateDelayBased` / `BweUpdateLossBased` | 带宽估计更新（延迟/丢包） |
| `DtlsTransportState` / `DtlsWritableState` | DTLS 传输状态 |
| `IceCandidatePairConfig` / `IceCandidatePairEvent` | ICE 候选对配置/事件 |
| `ProbeClusterCreated` / `ProbeResultFailure` / `ProbeResultSuccess` | 带宽探测 |
| `RtcpPacketIncoming` / `RtcpPacketOutgoing` | RTCP 包 |
| `RtpPacketIncoming` / `RtpPacketOutgoing` | RTP 包 |
| `VideoReceiveStreamConfig` / `VideoSendStreamConfig` | 视频流配置 |
| `GenericPacketSent` / `GenericPacketReceived` | 通用包收发 |
| `FrameDecoded` | 帧解码 |
| `NetEqSetMinimumDelay` | NetEq 最小延迟设置 |
| `BeginV3Log` / `EndV3Log` | V3 日志格式标记 |
| `FakeEvent` | 仅用于单元测试 |

**核心接口：**

| 方法 | 说明 |
|------|------|
| `GetType()` | 纯虚函数，返回事件类型 |
| `IsConfigEvent()` | 纯虚函数，是否为配置事件 |
| `GetGroupKey()` | 分组键，用于编码时分组优化压缩效率 |
| `timestamp_ms()` / `timestamp_us()` | 事件时间戳（毫秒/微秒） |

## 实现文件 (.cc)

- 默认构造函数使用 `TimeMillis() * 1000` 获取当前时间戳（微秒级）。
- 自定义时间戳通过受保护构造函数 `explicit RtcEvent(int64_t timestamp_us)` 设置。

## 学习扩展

- **RTC 事件日志**: WebRTC 的事件日志系统用于记录通话过程中的关键事件，用于事后分析和调试。事件日志可以编码为 protobuf 格式输出。
- **分组优化**: `GetGroupKey()` 允许事件按附加键（如 SSRC）分组编码，提升压缩效率。

## 设计模式

- **抽象基类模式** — `RtcEvent` 作为所有事件的基类，定义了通用接口。
- **模板方法模式** — 基类提供固定结构（时间戳存储），子类实现差异化行为（`GetType`, `IsConfigEvent`）。
- **组合模式（类型安全枚举）** — 通过 `Type` 枚举唯一标识所有事件子类类型。
