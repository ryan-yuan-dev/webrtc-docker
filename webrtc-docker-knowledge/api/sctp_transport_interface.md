# sctp_transport_interface

## 概述

`sctp_transport_interface.h` / `sctp_transport_interface.cc` 定义了 SCTP (Stream Control Transmission Protocol) 传输层的接口和状态信息结构，以及 SCTP 协商选项。SCTP 传输建立在 DTLS 传输之上，为 DataChannel 提供可靠/有序的数据传输服务。

在 WebRTC 架构中，该文件位于 `api/` 层，对应 W3C 规范的 `RTCSctpTransport` 接口。

## 头文件接口 (.h)

### 枚举 `SctpTransportState`

| 值 | 说明 |
|----|------|
| `kNew` | 尚未开始协商（非标准状态） |
| `kConnecting` | 正在协商 SCTP 关联 |
| `kConnected` | 关联协商完成 |
| `kClosed` | 本地或远端关闭 |

### 类 `SctpTransportInformation`
SCTP 传输的快照信息：

| 方法 | 说明 |
|------|------|
| `state()` | 传输状态 |
| `dtls_transport()` | 底层 DTLS 传输 |
| `MaxMessageSize()` | 最大消息大小 (bytes) |
| `MaxChannels()` | 最大通道数 |

### 类 `SctpTransportObserverInterface`

| 方法 | 说明 |
|------|------|
| `OnStateChange(SctpTransportInformation)` | 传输状态变化通知（在 network thread 调用） |

### 类 `SctpTransportInterface`

| 方法 | 说明 |
|------|------|
| `dtls_transport()` | 获取底层 DTLS 传输（可跨线程调用） |
| `Information()` | 获取状态快照（可跨线程调用） |
| `RegisterObserver(observer)` | 注册观察者 |
| `UnregisterObserver()` | 注销观察者 |

### 常量 `kSctpSendBufferSize`

```cpp
constexpr int kSctpSendBufferSize = 256 * 1024;  // 256 KiB
```

SCTP 关联发送缓冲区大小，对应 usrsctp 默认值。

### 结构体 `SctpOptions`
SCTP 选项，在 SDP 中协商：

| 字段 | 类型 | 说明 |
|------|------|------|
| `local_port` | `int` | 本地 SCTP 端口（-1 表示默认 `kSctpDefaultPort`） |
| `remote_port` | `int` | 远端 SCTP 端口（-1 表示默认 `kSctpDefaultPort`） |
| `max_message_size` | `int` | 最大消息大小（必须 <= `kSctpSendBufferSize`，默认 `kSctpSendBufferSize`） |

## 实现文件 (.cc)

### SctpTransportInformation 构造函数
- 默认构造：state = `kNew`。
- 单参构造：仅设置 state。
- 完整构造：state + dtls_transport + max_message_size + max_channels。

## 学习扩展

- SCTP 在 WebRTC 中运行在 DTLS 之上，提供可靠的、有序/无序的、带优先级的消息传输。
- `SctpTransportInterface` 的 `Information()` 可以跨线程调用，用于在不持有 network thread 的情况下安全读取传输状态。
- SCTP 端口在 SDP 中使用 `a=sctp-port` 属性协商，与底层 IP/端口无关。
- `max_message_size` 限制单个数据通道消息的最大长度，超过此限制的消息需要被应用层分片。
- 观察者回调在 network thread 上执行，实现 `OnStateChange` 时不应执行耗时操作。

## 设计模式

**不可变快照 (Immutable Snapshot)**：`SctpTransportInformation` 作为值传递的快照对象，在多线程间安全传递。

**观察者模式 (Observer)**：`SctpTransportObserverInterface` 用于状态变化通知。

**接口隔离 (Interface Segregation)**：`SctpTransportInterface` 对外提供最小接口，包括状态查询和观察者管理。
