# ice_transport_factory

## 概述

`ice_transport_factory.h` / `ice_transport_factory.cc` 提供了 `CreateIceTransport` 函数，用于创建一个独立的 ICE 传输对象，无需依赖完整的 PeerConnection 流程。这为需要底层 ICE 能力的应用程序提供了更轻量的入口。

在 WebRTC 架构中，该文件位于 `api/` 层，是 ICE 传输层的独立工厂。

## 头文件接口 (.h)

### 函数 `CreateIceTransport`

| 参数 | 类型 | 说明 |
|------|------|------|
| `init` | `IceTransportInit` | ICE 传输初始化参数，必须包含 `port_allocator()` |

| 返回值 | 说明 |
|--------|------|
| `scoped_refptr<IceTransportInterface>` | 新创建的 ICE 传输代理 |

要求：返回的对象必须在创建线程上访问和销毁。

## 实现文件 (.cc)

### IceTransportWithTransportChannel
文件内部定义了一个 `IceTransportWithTransportChannel` 类（继承自 `IceTransportInterface`），用于包装一个 `IceTransportInternal` 实例。

关键属性：
- 使用 `SequenceChecker` 确保所有操作在同一线程上执行。
- 通过 `RTC_GUARDED_BY` 注释确保成员 `internal_` 受线程检查保护。

### 创建流程
```cpp
scoped_refptr<IceTransportInterface> CreateIceTransport(IceTransportInit init) {
  return make_ref_counted<IceTransportWithTransportChannel>(
      P2PTransportChannel::Create("standalone", ICE_CANDIDATE_COMPONENT_RTP,
                                  std::move(init)));
}
```

`P2PTransportChannel::Create` 创建一个仅组件 RTP 的独立传输通道。

## 学习扩展

- 独立的 ICE Transport 可用于需要自定义 ICE 层但不使用完整 PeerConnection 的场景。
- `IceTransportInit` 包含 `port_allocator()`、可选的 `async_resolver_factory()` 和 `event_log()`。
- `SequenceChecker` 确保线程安全，跨线程访问会导致断言失败。

## 设计模式

**简单工厂 (Simple Factory)**：`CreateIceTransport` 封装了 `P2PTransportChannel` 和 `IceTransportWithTransportChannel` 的复杂创建逻辑。

**Proxy 模式 (Proxy)**：`IceTransportWithTransportChannel` 作为 `IceTransportInternal` 的代理包装，提供线程安全检查。

**接口隔离 (Interface Segregation)**：`IceTransportInterface` 作为纯接口，隐藏内部实现的复杂性。
