# time_controller

## 概述

`time_controller` 定义了 `TimeController` 接口，用于控制测试中的时间进度。该接口允许测试代码在实时模式或模拟时间模式下执行，通过不同的实现切换时间行为。

## 头文件接口 (.h)

### `TimeController` 抽象类

| 方法 | 说明 |
|------|------|
| `GetClock()` | 获取符合当前时间模式的时钟 |
| `GetTaskQueueFactory()` | 获取符合当前时间模式的任务队列工厂 |
| `CreateTaskQueueFactory()` | 创建可独立使用的 TaskQueueFactory 包装器 |
| `CreateThread(name, socket_server)` | 创建线程实例 |
| `GetMainThread()` | 获取主线程 |
| `AdvanceTime(duration)` | 推进时间前进，使任务队列执行 |
| `Wait(condition, max_duration)` | 轮询等待条件满足 |

## 实现文件 (.cc)

**`CreateTaskQueueFactory()`**: 使用包装器模式，将 `TimeController` 的 `GetTaskQueueFactory()` 返回的任务队列工厂包装为独立 `unique_ptr`，确保在 `TimeController` 销毁前销毁。

**`Wait()`**: 
1. 使用 5ms 步长执行轮询。
2. 每次步长调用 `AdvanceTime(kStep)` 使任务执行。
3. 在 `max_duration` 内检查 `condition()` 是否返回 true。
4. 超时后额外检查一次条件。

## 学习扩展

- **模拟时间**: 在模拟时间模式下，时间可以快速跳转，不受实际时钟限制，适用于需要长时间运行的测试。
- **TaskQueueFactory**: WebRTC 的任务队列抽象，在模拟时间下可以提供确定性的任务调度。

## 设计模式

- **策略模式** — 通过不同的 `TimeController` 实现切换实时/模拟时间策略。
- **适配器模式** — `CreateTaskQueueFactory()` 将内部 `TaskQueueFactory*` 适配为独立的 `unique_ptr`。
- **轮询模式（Polling）** — `Wait()` 使用轮询方式等待条件满足。
