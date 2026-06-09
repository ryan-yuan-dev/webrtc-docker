# datagram_connection_factory

## 概述

`datagram_connection_factory.h` / `datagram_connection_factory.cc` 提供了一个工厂函数 `CreateDatagramConnection`，用于创建 `DatagramConnection` 实例。DatagramConnection 是一个实验性的抽象连接层，基于 ICE 传输提供数据报（无连接）语义，不依赖于 PeerConnection 的完整协商流程。

在 WebRTC 架构中，该功能位于 `api/` 层，是 `pc/datagram_connection_internal.h` 实现的外部接口。

## 头文件接口 (.h)

### 函数 `CreateDatagramConnection`

| 参数 | 类型 | 说明 |
|------|------|------|
| `env` | `const Environment&` | WebRTC Environment 对象 |
| `port_allocator` | `unique_ptr<PortAllocator>` | ICE 端口分配器，用于候选收集 |
| `transport_name` | `string_view` | 传输通道名称 |
| `ice_controlling` | `bool` | 是否为 ICE controlling 角色 |
| `certificate` | `scoped_refptr<RTCCertificate>` | DTLS 证书 |
| `observer` | `unique_ptr<DatagramConnection::Observer>` | 事件观察者 |

| 返回值 | 说明 |
|--------|------|
| `scoped_refptr<DatagramConnection>` | 新创建的 DatagramConnection 实例 |

## 实现文件 (.cc)

### 执行流程
`CreateDatagramConnection` 函数创建一个 `DatagramConnectionInternal` 实例（继承自 `DatagramConnection`），将所有参数透传给构造函数：

```cpp
return make_ref_counted<DatagramConnectionInternal>(
    env, port_allocator, transport_name, ice_controlling, certificate, observer);
```

## 学习扩展

- `DatagramConnection` 提供一个轻量级的 ICE + DTLS 连接抽象，适合不需要完整 PeerConnection 功能的场景（如自定义数据传输层）。
- 该类的内部实现在 `pc/datagram_connection_internal.h` 中，完整的 ICE 候选收集、连通性检查和 DTLS 握手流程在此完成。
- 这可以看作是 WebRTC 底层传输能力的一个独立导出，类似于 `CreateIceTransport` 但不要求完整的 PeerConnection。

## 设计模式

**简单工厂 (Simple Factory)**：集中创建 `DatagramConnection` 对象，封装内部实现的构造细节。

**引用计数 (Reference Counting)**：通过 `make_ref_counted` 和 `scoped_refptr` 管理对象生命周期。
