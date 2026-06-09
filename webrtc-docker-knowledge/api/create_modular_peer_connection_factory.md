# create_modular_peer_connection_factory

## 概述

`create_modular_peer_connection_factory.h` / `create_modular_peer_connection_factory.cc` 提供了一个工厂函数 `CreateModularPeerConnectionFactory`，用于创建 `PeerConnectionFactoryInterface` 实例。该入口点允许应用程序按需注入可选依赖，减少不必要的模块链接，从而降低二进制体积。

在 WebRTC 架构中，该文件是 `PeerConnectionFactory` 创建的底层入口，`CreatePeerConnectionFactory`（便捷包装函数）内部最终调用此函数。

## 头文件接口 (.h)

### 函数 `CreateModularPeerConnectionFactory`

| 参数 | 类型 | 说明 |
|------|------|------|
| `dependencies` | `PeerConnectionFactoryDependencies` | 所有可选依赖通过此结构体注入 |

| 返回值 | 说明 |
|--------|------|
| `scoped_refptr<PeerConnectionFactoryInterface>` | 成功时返回 factory 实例，失败返回 nullptr |

函数声明为 `RTC_EXPORT`，表示是库的公共 API。

## 实现文件 (.cc)

### 线程安全处理
1. 检查调用线程是否是 `signaling_thread`。如果不是，使用 `BlockingCall` 将创建操作投递到 signaling 线程执行（递归调用），确保线程安全。
2. 在 `signaling_thread` 上调用 `PeerConnectionFactory::Create(std::move(dependencies))` 创建内部的 `PeerConnectionFactory`。
3. 验证初始化前后的线程一致性（`RTC_DCHECK_RUN_ON`）。
4. 使用 `PeerConnectionFactoryProxy::Create` 创建 proxy 包装，确保跨线程调用的安全性。

### 关键流程
```
CreateModularPeerConnectionFactory(deps)
  --> BlockingCall to signaling_thread (if needed)
    --> PeerConnectionFactory::Create(deps)
    --> PeerConnectionFactoryProxy::Create(signaling_thread, worker_thread, factory)
```

## 学习扩展

- `PeerConnectionFactoryDependencies` 结构体包含所有可选依赖：线程、网络工厂、事件日志、编解码器工厂、媒体引擎等。
- `PeerConnectionFactoryProxy` 通过 proxy 模式提供线程安全的访问，确保网络线程和工作线程上的调用被正确路由。
- 如果应用程序只使用 DataChannel 而不需要音视频，可以传入 `media_factory = nullptr`，避免链接媒体模块。

## 设计模式

**工厂方法模式 (Factory Method)**：集中创建 `PeerConnectionFactoryInterface` 的复杂对象。

**Proxy 模式 (Proxy Pattern)**：通过 `PeerConnectionFactoryProxy` 包装真实的工厂对象，提供线程安全的访问接口。

**依赖注入 (Dependency Injection)**：通过 `PeerConnectionFactoryDependencies` 结构体将依赖以参数形式注入，而非在内部创建。
