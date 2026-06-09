# resource

## 概述

`resource` 模块定义了 WebRTC 视频编码自适应（Adaptation）框架中的资源监控接口。`Resource` 用于监听系统资源的使用状态（如 CPU、网络带宽、内存等），当资源负载过高（`kOveruse`）或过低（`kUnderuse`）时触发相应的自适应动作。

## 头文件接口 (.h)

### `ResourceUsageState` 枚举

| 值 | 说明 |
|------|------|
| `kOveruse` | 资源过载，需要降低负载 |
| `kUnderuse` | 资源闲置，可以增加负载 |

### `ResourceListener` 接口

- **`OnResourceUsageStateMeasured(Resource, ResourceUsageState)`** — 纯虚方法，资源使用状态变化时调用。

### `Resource` 类

继承自 `RefCountInterface`（引用计数基类）：

| 方法 | 说明 |
|------|------|
| `Name()` | 返回资源名称，纯虚方法 |
| `SetResourceListener(ResourceListener*)` | 注册/移除监听器，nullptr 表示移除 |
| `Resource()` / `~Resource()` | 构造/析构 |

## 实现文件 (.cc)

- `ResourceUsageStateToString()` — 将枚举值转为可读字符串，用于日志和调试。
- `ResourceListener` 和 `Resource` 的析构函数为空的虚实现。

## 学习扩展

- **视频编码自适应**: WebRTC 的 Adaptation 框架根据资源条件动态调整视频编码参数（分辨率、帧率、码率），以保持通话质量。资源包括 CPU（编码/解码负载）、网络带宽、屏幕捕获等。
- **引用计数的设计意义**: `Resource` 继承 `RefCountInterface` 是因为资源使用测量可能发生在其他任务队列，测量结果通过回调传递，引用计数防止在传递过程中对象被销毁。
- **自适应任务队列**: API 注释指出所有 `Resource` 的方法在 adaptation task queue 上调用，而测量工作可在任何任务队列上执行。

## 设计模式

- **观察者模式** — `Resource` 作为被观察者，`ResourceListener` 作为观察者。资源状态变化时通知监听者执行自适应动作。
- **策略模式（资源监控策略）** — 不同的资源实现（CPU、带宽等）共享相同的 `Resource` 接口。
- **引用计数模式** — 继承 `RefCountInterface` 确保跨任务队列的对象生命周期安全。
