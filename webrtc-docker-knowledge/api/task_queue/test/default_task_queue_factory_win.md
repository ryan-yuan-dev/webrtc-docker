# default_task_queue_factory_win

## 概述

`default_task_queue_factory_win.cc` 是 Windows 平台上默认任务队列工厂的实现。该文件使用 Windows Thread Pool API 创建任务队列实例。

## 实现

```cpp
#include "api/field_trials_view.h"
#include "api/task_queue/task_queue_factory.h"
#include "rtc_base/task_queue_win.h"

namespace webrtc {

std::unique_ptr<TaskQueueFactory> CreateDefaultTaskQueueFactory(
    const FieldTrialsView* field_trials) {
  return CreateTaskQueueWinFactory();
}

}  // namespace webrtc
```

- 委托给 `rtc_base/task_queue_win.h` 中的 `CreateTaskQueueWinFactory()`

## 学习扩展

### Windows 实现的底层机制

`task_queue_win` 实现使用：
- **Windows Thread Pool API** (`CreateThreadpoolWork`, `SubmitThreadpoolWork`): 异步任务调度
- **Windows Timer Queues** (`CreateTimerQueue`, `CreateTimerQueueTimer`): 延迟任务
- **SRWLock** (Slim Reader/Writer Lock): 轻量级同步原语

### Windows 实现的特性

| 特性 | 说明 |
|------|------|
| 线程池 | 共享线程池，非专有线程模型 |
| 延迟精度 | 高精度定时器（~1ms 精度） |
| 电池影响 | 电池供电时定时器精度可能降为 ~15ms |
| 资源效率 | 线程池共享，比 1:1 线程模型更高效 |

### Windows 定时器精度

Windows 在电池供电时默认使用较粗的定时器精度以省电。如果需要高精度定时，可能需要调用 `timeBeginPeriod(1)` 请求 1ms 精度，但这会增加功耗。

## 设计模式

| 模式 | 说明 |
|------|------|
| **Factory Method** | 平台特定的默认工厂函数 |
| **Adapter** | 将 Windows Thread Pool API 适配为 TaskQueueBase 接口 |
