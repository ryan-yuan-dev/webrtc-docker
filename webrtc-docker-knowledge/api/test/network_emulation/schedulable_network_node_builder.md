# schedulable_network_node_builder

## 概述

`SchedulableNetworkNodeBuilder` 是一个 Builder，用于根据预定义的 `NetworkConfigSchedule`（基于 protobuf）创建可按时间策略改变网络行为的模拟网络节点。支持设置启动条件，在网络节点启动前使用配置计划中的第一个配置项，启动条件满足后按计划动态切换。

## 头文件接口 (.h)

### `SchedulableNetworkNodeBuilder` 类

- **`SchedulableNetworkNodeBuilder(net, schedule)`** — 构造，绑定网络模拟管理器和配置调度计划
- **`set_start_condition(start_condition)`** — 设置启动条件，参数为 `bool(Timestamp)` 可调用对象，默认始终返回 true
- **`Build(random_seed)`** — 创建 `EmulatedNetworkNode`，使用 `SchedulableNetworkBehavior` 作为行为实现

## 实现文件 (.cc)

- 默认启动条件为 `[](Timestamp) { return true; }`。
- `Build()` 方法从 time controller 获取当前时间作为随机种子。
- 创建 `SchedulableNetworkBehavior` 实例并传递给 `CreateEmulatedNode()`。

## 学习扩展

- **NetworkConfigSchedule (protobuf)**: 使用 protobuf 格式定义网络配置的时间调度计划。
- **SchedulableNetworkBehavior**: 在 `test/network/` 目录中实现的`NetworkBehaviorInterface`，支持按时间计划动态调整延迟、丢包率等参数。

## 设计模式

- **Builder 模式** — 链式配置后构建最终产品。
- **策略模式** — 通过 `SchedulableNetworkBehavior` 实现可调度的网络行为策略。
- **条件启动模式** — 通过 `start_condition` 控制行为调度的启动时机。
