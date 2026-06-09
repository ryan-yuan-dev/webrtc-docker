# default_neteq_controller_factory

## 概述

`default_neteq_controller_factory` 模块提供 WebRTC 默认的 NetEqController 工厂实现。它使用内置的 `DelayManager` 和 `DecisionLogic` 创建标准的 NetEq 控制逻辑，不依赖任何自定义组件。

## 头文件接口 (.h)

### `DefaultNetEqControllerFactory` 类

继承自 `NetEqControllerFactory`：

- **`DefaultNetEqControllerFactory()`** — 默认构造函数。
- **`Create(env, config)`** — 创建 WebRTC 内置控制逻辑的 `NetEqController`。

## 实现文件 (.cc)

### 关键实现逻辑

1. 默认构造函数和析构函数均为 `= default`。
2. `Create()` 方法：
   - 创建 `DelayManager`，使用 `DelayManager::Config`（从 field trials 获取默认值）和 `tick_timer`。
   - 创建 `DecisionLogic`，将 config 和 DelayManager 注入。
3. 这两个类均来自 `modules/audio_coding/neteq/` 内部模块。

## 学习扩展

- **默认实现 vs 自定义实现**: `DefaultNetEqControllerFactory` 是 `CustomNetEqControllerFactory` 的对应默认版本，两者都创建相同的 `DecisionLogic`，区别在于 `DelayManager` 的来源。
- **DelayManager::Config**: 从 `env.field_trials()` 读取默认配置，这意味着 WebRTC 的 field trials 可以动态调整延迟管理参数。

## 设计模式

- **工厂方法模式** — 提供创建 `NetEqController` 的方法封装。
- **策略模式**（默认策略） — 作为内置策略，通常无需额外设置。
