# custom_neteq_controller_factory

## 概述

`custom_neteq_controller_factory` 模块提供了一种自定义 NetEqController 的工厂实现。通过接收一个自定义的 `DelayManagerFactory`，允许使用者替换 NetEq 内部的延迟管理逻辑，从而定制抖动缓冲的行为策略。

## 头文件接口 (.h)

### `CustomNetEqControllerFactory` 类

继承自 `NetEqControllerFactory`：

- **`CustomNetEqControllerFactory(unique_ptr<DelayManagerFactory>)`** — 构造函数，接收自定义的 DelayManagerFactory 的所有权。
- **`Create(env, config)`** — 创建 `NetEqController` 实例，使用自定义的延迟管理器。

## 实现文件 (.cc)

### 关键实现逻辑

1. 构造函数接收 `DelayManagerFactory` 的 unique_ptr，将其存储为成员变量。
2. `Create()` 方法中：
   - 使用 `RTC_DCHECK` 确保 `delay_manager_factory_` 非空。
   - 调用 `delay_manager_factory_->Create()` 创建自定义的 `DelayManager`。
   - 将自定义 DelayManager 注入到 `DecisionLogic`（NetEq 控制逻辑的核心实现类）。
3. 使用了 `modules/audio_coding/neteq/` 内部的 `DecisionLogic` 类，这表明自定义工厂的粒度在于 "替换延迟管理器，保留默认决策逻辑"。

## 学习扩展

- **DelayManager**: 负责计算目标延迟、管理抖动尖峰检测和延迟控制的组件。
- **NetEqController**: 控制 NetEq 的核心决策组件，决定何时进行扩频、缩频等操作。
- **工厂组合**: 通过不同的工厂层次（NetEqFactory -> NetEqControllerFactory -> DelayManagerFactory）实现了可组合的自定义机制。

## 设计模式

- **抽象工厂模式** — `NetEqControllerFactory` 是抽象工厂接口，`CustomNetEqControllerFactory` 是具体实现。
- **策略模式** — 延迟管理策略通过 `DelayManagerFactory` 注入，可动态替换。
- **依赖注入** — 通过构造函数注入依赖，符合 SOLID 原则中的依赖倒置原则。
