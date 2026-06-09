# default_task_queue_factory_stdlib

## 概述

`default_task_queue_factory_stdlib.cc` 是 POSIX/Linux 平台上默认任务队列工厂的实现（fallback 实现）。该文件使用 C++ 标准库的线程原语 (`std::thread`) 创建任务队列实例。

## 实现

```cpp
#include "api/field_trials_view.h"
#include "api/task_queue/task_queue_factory.h"
#include "rtc_base/task_queue_stdlib.h"

namespace webrtc {

std::unique_ptr<TaskQueueFactory> CreateDefaultTaskQueueFactory(
    const FieldTrialsView* field_trials) {
  return CreateTaskQueueStdlibFactory();
}

}  // namespace webrtc
```

- 委托给 `rtc_base/task_queue_stdlib.h` 中的 `CreateTaskQueueStdlibFactory()`

## 学习扩展

### stdlib 实现的底层机制

`task_queue_stdlib` 实现使用：
- `std::thread`: 一个任务队列一个专用线程
- `std::mutex` + `std::condition_variable`: 任务同步
- `std::priority_queue`: 管理延迟任务的定时触发

### 适用场景

- Linux 桌面环境
- Android 平台（Android 也使用此实现）
- 无法使用 GCD 或 Windows API 的平台

### 性能特点

| 方面 | 说明 |
|------|------|
| 线程模型 | 1 队列 = 1 线程，专有线程模型 |
| 延迟精度 | 依赖 `std::condition_variable::wait_for`，精度 ~1ms |
| 唤醒开销 | 每次延迟任务触发涉及线程唤醒和锁竞争 |
| 资源消耗 | 每创建一个任务队列就创建一个线程 |

## 设计模式

| 模式 | 说明 |
|------|------|
| **Factory Method** | 平台特定的默认工厂函数 |
| **Adapter** | 将 std::thread 适配为 TaskQueueBase 接口 |
