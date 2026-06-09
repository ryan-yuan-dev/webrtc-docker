# create_network_emulation_manager

## 概述

`create_network_emulation_manager` 模块提供 `NetworkEmulationManager` 实例的创建工厂函数。用于在测试中创建网络模拟环境。

## 头文件接口 (.h)

### 工厂函数

| 函数 | 说明 |
|------|------|
| `CreateNetworkEmulationManager(config)` | 使用 `NetworkEmulationManagerConfig` 创建，新版 API |
| `CreateNetworkEmulationManager(time_mode, stats_gathering_mode, field_trials)` | 已废弃，使用三个独立参数创建 |

## 实现文件 (.cc)

- 新版 `CreateNetworkEmulationManager(config)` 创建 `test::NetworkEmulationManagerImpl` 实例。
- 已废弃版本将三个参数构造为 `NetworkEmulationManagerConfig` 后委托给新版函数。

## 学习扩展

- **NetworkEmulationManagerConfig**: 包含时间模式（实时/模拟）、统计收集模式、field trials、DTLS 握手大小伪造选项。

## 设计模式

- **工厂方法模式** — 封装 `NetworkEmulationManagerImpl` 的创建细节。
- **参数对象模式** — `NetworkEmulationManagerConfig` 作为参数对象简化 API。
