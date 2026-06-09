# network_emulation_manager

## 概述

`network_emulation_manager` 模块定义了网络模拟管理器的核心接口 `NetworkEmulationManager`，用于在测试环境中创建和配置仿真的网络拓扑。支持创建端点（Endpoint）、路由（Route）、网络节点（NetworkNode）、TCP 消息路由、交叉流量生成器等组件，模拟真实网络环境中的各种条件（带宽限制、延迟、丢包等）。

## 头文件接口 (.h)

### 数据结构

**`EmulatedNetworkStatsGatheringMode`**：统计收集模式
- `kDefault` — 基础统计
- `kDebug` — 额外收集每包统计

**`EmulatedEndpointConfig`**：端点配置，包括 IP 地址族、起始启用状态、网络类型等。

**`EmulatedTURNServerConfig`**：TURN 服务器端点配置。

**`NetworkEmulationManagerConfig`**：管理器配置
- `time_mode` — 实时或模拟时间
- `stats_gathering_mode` — 统计模式
- `field_trials` — Field trials 配置
- `fake_dtls_handshake_sizes` — 是否使用固定 DTLS 握手大小

### 接口定义

**`EmulatedTURNServerInterface`** — TURN 服务器接口，提供 ICE Server 配置、客户端和服务端端点。

**`EmulatedNetworkManagerInterface`** — 继承 `PeerNetworkDependencies`，提供端点列表和统计获取。

**`TimeMode`** 枚举：`kRealTime`（实时）/ `kSimulated`（模拟）。

**`NetworkEmulationManager`** 核心接口：

| 方法 | 说明 |
|------|------|
| `time_controller()` | 获取时间控制器 |
| `CreateEmulatedNode(config)` | 创建网络节点 |
| `NodeBuilder()` | 获取节点 Builder |
| `CreateEndpoint(config)` | 创建网络端点 |
| `EnableEndpoint()` / `DisableEndpoint()` | 启用/禁用端点 |
| `CreateRoute(from, via_nodes, to)` | 创建路由 |
| `CreateDefaultRoute(...)` | 创建默认路由 |
| `ClearRoute(route)` | 移除路由 |
| `CreateTcpRoute(send_route, ret_route)` | 创建模拟 TCP 路由 |
| `CreateCrossTrafficRoute(via_nodes)` | 创建交叉流量路由 |
| `StartCrossTraffic(generator)` | 开始生成交叉流量 |
| `StopCrossTraffic(generator)` | 停止交叉流量 |
| `CreateEmulatedNetworkManagerInterface(endpoints)` | 创建网络管理器接口 |
| `CreateTURNServer(config)` | 创建 TURN 服务器 |
| `CreateEndpointPairWithTwoWayRoutes(config)` | 创造一对点对点互联 |

**`SimulatedNetworkNode::Builder`** — Builder 模式构造模拟网络节点，支持配置：
- `config()` / `queue_factory()` / `delay_ms()` / `capacity()` / `capacity_kbps()` / `capacity_Mbps()` / `loss()` / `packet_queue_length()` / `delay_standard_deviation_ms()` / `allow_reordering()` / `avg_burst_loss_length()` / `packet_overhead()` / `Build()`

## 实现文件 (.cc)

- `AbslParseFlag` / `AbslUnparseFlag` — `TimeMode` 枚举的 `absl::Flag` 解析/序列化支持。
- `SimulatedNetworkNode::Builder` 各设置方法直接修改 `BuiltInNetworkBehaviorConfig` 成员。
- `Builder::Build()` — 创建 `SimulatedNetwork` 行为实例，使用默认 `LeakyBucketNetworkQueue` 或自定义 `NetworkQueueFactory`。
- `CreateEndpointPairWithTwoWayRoutes()` — 便捷方法，创建两个端点并建立双向路由。

## 学习扩展

- **网络模拟架构**: WebRTC 的网络模拟在操作系统的虚拟 UDP socket 层面工作，不涉及真实网络接口。
- **BuiltInNetworkBehaviorConfig**: 内建网络行为配置，包含延迟、丢包率、带宽、抖动等参数。
- **SimulatedNetwork**: 实现了 `NetworkBehaviorInterface` 的具体行为模拟器。
- **交叉流量（Cross Traffic）**: 模拟网络上除了被测媒体流之外的背景流量。

## 设计模式

- **工厂模式** — 大量使用工厂方法创建网络组件。
- **Builder 模式** — `SimulatedNetworkNode::Builder` 提供链式调用配置网络节点。
- **外观模式** — `NetworkEmulationManager` 作为整个网络模拟系统的统一入口。
- **组合模式** — 路由由端点和网络节点组成，节点可以组合为链式路径。
