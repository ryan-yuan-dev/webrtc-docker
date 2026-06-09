# custom_neteq_factory

## 概述

`custom_neteq_factory` 模块提供了一种完全自定义 NetEq 实例的工厂实现。它接收一个自定义的 `NetEqControllerFactory`，允许使用者替换 NetEq 内部完整的控制逻辑（包括延迟管理、决策逻辑等）。

## 头文件接口 (.h)

### `CustomNetEqFactory` 类

继承自 `NetEqFactory`：

- **`CustomNetEqFactory(unique_ptr<NetEqControllerFactory>)`** — 构造函数，接收自定义的 NetEqControllerFactory 的所有权。
- **`Create(env, config, decoder_factory)`** — 使用自定义控制器工厂创建完整的 `NetEq` 实例。

## 实现文件 (.cc)

### 关键实现逻辑

1. 构造函数存储传入的 `NetEqControllerFactory`。
2. `Create()` 方法中：
   - 构造 `NetEqImpl::Dependencies`（即 NetEq 实现的所有依赖项），将自定义的 `controller_factory_` 传入。
   - 创建 `NetEqImpl` 实例。
3. 与 `DefaultNetEqFactory` 唯一的不同在于使用了自定义的 `NetEqControllerFactory`，允许替换从延迟管理到决策逻辑的完整控制链。

## 学习扩展

- **NetEqImpl::Dependencies**: 这是 NetEq 实现所需的全部依赖项的聚合体，`CustomNetEqFactory` 通过注入自定义的 controller factory 来影响整个依赖链。
- **控制反转**: `CustomNetEqFactory` 将控制器的选择权交给调用方，只负责装配 NetEq 实例。

## 设计模式

- **抽象工厂模式** — `NetEqFactory` 是抽象工厂，`CustomNetEqFactory` 是具体实现。
- **依赖注入** — 通过构造函数注入控制器工厂。
- **装饰器模式**（类比） — `CustomNetEqFactory` 包装了一个 `NetEqControllerFactory`，在保持 `NetEqFactory` 接口不变的同时替换内部行为。
