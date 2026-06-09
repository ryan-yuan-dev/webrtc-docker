# rtc_event_log_factory

## 概述

`rtc_event_log_factory` 模块提供了 `RtcEventLog` 实例的工厂实现 `RtcEventLogFactory`。它根据编译配置（`WEBRTC_ENABLE_RTC_EVENT_LOG` 宏）和运行时配置（field trial kill switch）决定创建实际的日志实现还是空操作实现。

## 头文件接口 (.h)

### `RtcEventLogFactory` 类

继承自 `RtcEventLogFactoryInterface`：

- **`RtcEventLogFactory()`** — 默认构造。
- **`RtcEventLogFactory(TaskQueueFactory*)`** — 已废弃，保留用于向后兼容。
- **`Create(const Environment&)`** — 根据环境和编译配置创建 `RtcEventLog`。

## 实现文件 (.cc)

### 关键实现逻辑

`Create()` 方法中的决策逻辑：
1. 如果未定义 `WEBRTC_ENABLE_RTC_EVENT_LOG` 宏 → 返回 `RtcEventLogNull`（空实现）。
2. 如果定义了宏，但 field trial `WebRTC-RtcEventLogKillSwitch` 被启用 → 返回 `RtcEventLogNull`。
3. 否则 → 返回 `RtcEventLogImpl` 实例（实际的事件日志实现，在 `logging/rtc_event_log/` 模块中）。

这种设计提供了编译时和运行时两级控制：
- 编译时：通过宏完全禁用日志功能，减小二进制体积。
- 运行时：通过 field trial 实现远程杀开关（Kill Switch），紧急情况下禁用日志。

## 学习扩展

- **Kill Switch 机制**: WebRTC 使用 field trial 作为远程功能开关。这在 production 环境中紧急禁用某些功能时非常有用。
- **编译时 vs 运行时**: 两级控制策略的权衡 —— 编译时开关减小二进制，运行时开关提供灵活性。
- **RtcEventLogImpl**: 位于 `logging/rtc_event_log/` 模块，是事件日志的实际编码和输出实现。

## 设计模式

- **工厂方法模式** — `Create()` 封装了 `RtcEventLog` 创建的决策逻辑。
- **条件工厂模式** — 根据环境和编译条件返回不同实现。
- **策略模式（运行时策略）** — 通过 field trial 动态切换日志行为。
