# data_channel_interface

## 概述

`data_channel_interface.h` / `data_channel_interface.cc` 定义了 WebRTC DataChannel 的核心接口。DataChannel 允许端到端传输任意应用数据（文本或二进制），基于 SCTP over DTLS 实现，对应 W3C WebRTC 规范的 RTCDataChannel 接口。

在 WebRTC 架构中，该接口位于 `api/` 层，所有 DataChannel 实现（包括 SCTP 和实验性实现）都必须遵循此接口契约。

## 头文件接口 (.h)

### 结构体 `DataChannelInit`
对应 W3C `RTCDataChannelInit` dictionary：

| 成员 | 类型 | 说明 |
|------|------|------|
| `reliable` | `bool` | (已废弃) 默认 true |
| `ordered` | `bool` | 是否需要有序投递 |
| `maxRetransmitTime` | `optional<int>` | 最大重传时间 (ms)，不能与 `maxRetransmits` 同时设置 |
| `maxRetransmits` | `optional<int>` | 最大重传次数，不能与 `maxRetransmitTime` 同时设置 |
| `protocol` | `string` | 子协议标识（应用层透明，WebRTC 不解析） |
| `negotiated` | `bool` | 是否已外部协商 ID |
| `id` | `int` | SCTP 流 ID（已协商时必填，否则自动分配） |
| `priority` | `optional<PriorityValue>` | W3C 优先级标准扩展 |

### 结构体 `DataBuffer`
封装待传输的数据：

| 成员 | 说明 |
|------|------|
| `data` | `CopyOnWriteBuffer` 类型，承载实际数据 |
| `binary` | 标识数据为二进制 (true) 或文本 UTF-8 (false) |

### 类 `DataChannelObserver`
接收 DataChannel 事件的纯虚接口：

| 方法 | 说明 |
|------|------|
| `OnStateChange()` | 状态变化通知 |
| `OnMessage(const DataBuffer&)` | 接收到的数据消息 |
| `OnBufferedAmountChange(uint64_t)` | 缓冲区数据量变化 |
| `IsOkToCallOnTheNetworkThread()` | 返回 true 时，回调将在 network thread 触发（默认 false，即 signaling thread） |

### 类 `DataChannelInterface`

| 方法 | 说明 |
|------|------|
| `RegisterObserver` / `UnregisterObserver` | 注册/注销事件观察者 |
| `label()` | Channel 标签 |
| `reliable()` / `ordered()` / `maxRetransmitsOpt()` / `maxPacketLifeTime()` / `protocol()` / `negotiated()` | DataChannelInit 中的配置属性 |
| `id()` | SCTP 流 ID |
| `priority()` | Channel 优先级 |
| `state()` | 当前状态（kConnecting / kOpen / kClosing / kClosed） |
| `error()` | 非正常关闭时的错误信息 |
| `messages_sent()` / `bytes_sent()` / `messages_received()` / `bytes_received()` | 统计计数 |
| `buffered_amount()` | 尚未发送的字节数 |
| `Close()` | 启动优雅关闭流程 |
| `Send(const DataBuffer&)` | 同步发送数据 |
| `SendAsync(DataBuffer, callback)` | 异步发送数据，完成后回调 |
| `MaxSendQueueSize()` | 最大发送队列大小（static 方法） |

### 枚举 `DataState`

| 值 | 说明 |
|----|------|
| `kConnecting` | 正在建立连接 |
| `kOpen` | 已就绪，可收发数据 |
| `kClosing` | 正在关闭 |
| `kClosed` | 已关闭 |

## 实现文件 (.cc)

### 默认实现
多数属性有默认实现，便于子类不需要覆盖所有纯虚方法：
- `ordered()` 返回 `false`
- `maxRetransmitsOpt()` 和 `maxPacketLifeTime()` 返回 `nullopt`
- `protocol()` 返回空字符串
- `negotiated()` 返回 `false`
- `priority()` 返回 `Priority::kLow`
- `Send()` 和 `SendAsync()` 调用 `RTC_DCHECK_NOTREACHED()`，期望被子类覆盖

### MaxSendQueueSize
`MaxSendQueueSize()` 返回固定值 `16 MiB`，超出此限制后 Send 返回 false。

## 学习扩展

- DataChannel 支持无序投递 (`ordered = false`)，此时可获取更低延迟。
- `DataChannelInit::negotiated = true` 且 `id` 已指定时，两端可以预知通道 ID 而无需 SDP 协商。
- `DataChannelObserver` 的回调默认运行在 signaling thread，性能敏感的观察者应覆盖 `IsOkToCallOnTheNetworkThread()` 以在 network thread 接收回调。
- SCTP 映射到 DataChannel 流 ID 上，流 ID 是 0-65535 的无符号短整型。

## 设计模式

**观察者模式 (Observer Pattern)**：`DataChannelObserver` 提供状态变更和数据到达回调，支持单观察者注册。

**接口分离原则 (Interface Segregation)**：`DataChannelInterface` 定义了 DataChannel 的完整契约，而 `DataChannelObserver` 只关注事件通知，两者职责清晰分离。

**模板方法模式的变体**：基类 `DataChannelInterface` 为大部分属性方法提供默认实现，子类只需覆盖必要的方法。
