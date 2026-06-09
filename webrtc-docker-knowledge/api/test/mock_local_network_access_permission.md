# mock_local_network_access_permission

## 概述

`mock_local_network_access_permission` 提供了用于测试的 `LocalNetworkAccessPermission` 模拟和假实现。包含 `MockLocalNetworkAccessPermission`（GMock 模拟）和 `FakeLocalNetworkAccessPermissionFactory`（可配置结果的假工厂）。

## 头文件接口 (.h)

### `MockLocalNetworkAccessPermission` 类

继承 `LocalNetworkAccessPermissionInterface`，使用 GMock 模拟：
- `ShouldRequestPermission(SocketAddress)` — 是否应请求权限
- `RequestPermission(SocketAddress, callback)` — 请求权限并异步回调结果

### `MockLocalNetworkAccessPermissionFactory` 类

继承 `LocalNetworkAccessPermissionFactoryInterface`：
- `Create()` — 创建 `MockLocalNetworkAccessPermission` 实例

### `FakeLocalNetworkAccessPermissionFactory` 类

继承 `MockLocalNetworkAccessPermissionFactory`，提供可配置的结果：

| 结果枚举 | 行为 |
|---------|------|
| `kPermissionNotNeeded` | `ShouldRequestPermission` 返回 `false` |
| `kPermissionGranted` | 请求权限并通过异步回调返回 `kGranted` |
| `kPermissionDenied` | 请求权限并通过异步回调返回 `kDenied` |

## 实现文件 (.cc)

- 在构造函数中设置 GMock `EXPECT_CALL`，预定义 `Create()` 和 `ShouldRequestPermission()` 的返回值。
- `RequestPermission` 通过 `Thread::Current()->PostTask()` 异步回调，模拟真实异步请求的时序。

## 学习扩展

- **GMock**: Google Test 的 mock 框架，用于创建模拟对象。
- **Local Network Access**: WebRTC 中控制对本地网络访问的权限机制，用于安全场景。

## 设计模式

- **Mock 对象模式** — 使用 GMock 创建可控制行为的测试替身。
- **工厂方法模式** — `Create()` 工厂方法创建权限实现实例。
- **异步回调模式** — 通过 `PostTask` 模拟异步权限请求结果通知。
