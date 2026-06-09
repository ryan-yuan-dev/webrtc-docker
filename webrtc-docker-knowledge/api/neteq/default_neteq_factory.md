# default_neteq_factory

## 概述

`default_neteq_factory` 模块提供 WebRTC 默认的 NetEq 完整工厂实现。它内部持有一个 `DefaultNetEqControllerFactory`，使用 WebRTC 内置的默认控制逻辑创建 `NetEq` 实例。

## 头文件接口 (.h)

### `DefaultNetEqFactory` 类

继承自 `NetEqFactory`：

- **`DefaultNetEqFactory()`** — 默认构造函数。
- **`Create(env, config, decoder_factory)`** — 创建默认的完整 `NetEq` 实例。

私有成员：
- `const DefaultNetEqControllerFactory controller_factory_` — 内置的默认控制器工厂。

## 实现文件 (.cc)

### 关键实现逻辑

1. 内部持有 `DefaultNetEqControllerFactory` 的 const 实例，通过 `controller_factory_` 成员提供。
2. `Create()` 方法：
   - 构造 `NetEqImpl::Dependencies`，传入 `controller_factory_`（注意是 const 引用）。
   - 创建 `NetEqImpl` 实例并返回。

## 学习扩展

- **工厂组合**: `DefaultNetEqFactory` 内部组合了 `DefaultNetEqControllerFactory`，形成了两层工厂架构。
- **NetEqFactory 接口**: 统一所有 NetEq 创建的入口，便于替换为 `CustomNetEqFactory`。
- **NetEqImpl**: NetEq 的具体实现类，位于 `modules/audio_coding/neteq/` 内部模块。

## 设计模式

- **工厂方法模式** — 创建 `NetEq` 实例的统一入口。
- **组合模式** — 将控制器工厂作为成员组合在 NetEq 工厂中。
- **策略模式（默认策略）** — 作为系统默认的 NetEq 构建策略，需要自定义策略时用 `CustomNetEqFactory` 替换。
