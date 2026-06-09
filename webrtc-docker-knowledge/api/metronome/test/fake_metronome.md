# fake_metronome

## 概述

`fake_metronome` 模块提供了两种用于测试的 Metronome（节拍器）实现：`ForcedTickMetronome` 和 `FakeMetronome`。Metronome 是 WebRTC 中一个定时触发回调的抽象接口，类似于一个周期性的定时器，用于音频编码等周期性任务的时间同步。

## 头文件接口 (.h)

### `ForcedTickMetronome` 类

手动触发的节拍器，通过显式调用 `Tick()` 驱动回调执行：

- **`ForcedTickMetronome(TimeDelta tick_period)`** — 以指定周期构造。
- **`Tick()`** — 强制触发所有已注册的回调。
- **`NumListeners()`** — 返回当前注册的回调数。
- **`RequestCallOnNextTick(callback)`** — 注册回调，在下一次"滴答"时执行。
- **`TickPeriod()`** — 返回配置的滴答周期。

### `FakeMetronome` 类

基于任务队列定时器自动触发的节拍器，适用于模拟任务队列的单元测试：

- **`FakeMetronome(TimeDelta tick_period)`** — 以指定周期构造。
- **`SetTickPeriod(TimeDelta)`** — 运行时修改滴答周期。
- **`RequestCallOnNextTick(callback)`** — 注册回调，通过 `TaskQueueBase::PostDelayedTask` 在指定延迟后触发。
- **`TickPeriod()`** — 返回配置的滴答周期。

## 实现文件 (.cc)

### `ForcedTickMetronome` 实现

- `Tick()` 方法将当前回调列表通过 swap 移出（确保执行中注册的新回调不在此次执行），然后逐个执行。
- 这种 "swap-then-execute" 模式防止回调执行中间接注册新回调导致无限递归。

### `FakeMetronome` 实现

- `RequestCallOnNextTick()` 首次注册回调时（`callbacks_.size() == 1`），通过 `TaskQueueBase::Current()->PostDelayedTask()` 在 `tick_period_` 后触发批量执行。
- 这种设计模拟了真实 Metronome 的行为：多个请求在同一个 tick 中批量处理。
- `SetTickPeriod()` 允许在测试中动态改变节拍周期。

## 学习扩展

- **Metronome 的用途**: WebRTC 的 `Metronome` 在 `modules/audio_coding/` 中使用，用于同步音频编码器的周期性编码操作。
- **TaskQueueBase**: WebRTC 的任务队列抽象，`FakeMetronome` 依赖当前任务队列来安排定时任务。
- **Swap-and-execute 模式**: 防止回调重入的常见 C++ 惯用法。

## 设计模式

- **适配器模式** — 将测试控制逻辑适配到 `Metronome` 接口上。
- **命令模式** — 回调函数封装为 `absl::AnyInvocable<void()&&>`，支持任意可调用对象。
- **回收集合（Batch Execution）** — 同一 tick 内的多个回调在同一个循环中批量执行。
