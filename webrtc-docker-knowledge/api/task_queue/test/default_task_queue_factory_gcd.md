# default_task_queue_factory_gcd

## 概述

`default_task_queue_factory_gcd.cc` 是 macOS/iOS 平台上默认任务队列工厂的实现。该文件通过 Grand Central Dispatch (GCD) 创建任务队列实例，是 Apple 平台上的最佳实现选择。

## 实现

```cpp
#include "api/field_trials_view.h"
#include "api/task_queue/task_queue_factory.h"
#include "rtc_base/task_queue_gcd.h"

namespace webrtc {

std::unique_ptr<TaskQueueFactory> CreateDefaultTaskQueueFactory(
    const FieldTrialsView* /* field_trials */) {
  return CreateTaskQueueGcdFactory();
}

}  // namespace webrtc
```

- 忽略 `field_trials` 参数（GCD 无需试验配置）
- 委托给 `rtc_base/task_queue_gcd.h` 中的 `CreateTaskQueueGcdFactory()`

## 学习扩展

### GCD 的优势

Grand Central Dispatch 是 Apple 的并发编程框架，提供：
- **Dispatch Queues**: 轻量级任务队列，底层由线程池管理
- **QoS 等级**: 支持服务质量等级（User Interactive, User Initiated, Utility, Background）
- **定时器**: `dispatch_source_t` 提供高效的低功耗定时器

### 与其他平台实现的对比

| 平台 | 实现 | 底层机制 |
|------|------|----------|
| macOS/iOS | `task_queue_gcd.cc` | GCD dispatch queues |
| Linux/POSIX | `task_queue_stdlib.cc` | std::thread + 条件变量 |
| Windows | `task_queue_win.cc` | Windows Thread Pool API |

## 设计模式

| 模式 | 说明 |
|------|------|
| **Factory Method** | 平台特定的默认工厂函数 |
| **Adapter** | 将 GCD dispatch queue 适配为 WebRTC TaskQueueBase 接口 |
