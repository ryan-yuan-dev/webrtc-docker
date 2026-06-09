# WebRTC 任务队列 API 文档

## 概述

`api/task_queue/` 定义了 WebRTC 的异步任务调度系统。WebRTC 是一个高度异步的系统——网络事件、编码完成回调、定时器等都需要在正确的线程上执行。

---

## 一、TaskQueueBase（任务队列基类）

### task_queue_base.cc
**路径**: `api/task_queue/task_queue_base.cc`
**关键类**: `TaskQueueBase`, `TaskQueueBase::CurrentTaskQueueSetter`

WebRTC 任务队列系统的核心抽象。通过 TLS (Thread Local Storage) 提供「当前任务队列」的访问能力。

**Current()** — 获取当前线程关联的 TaskQueue:
- **有 `thread_local` 平台** (C++11): 使用 `thread_local TaskQueueBase* current` — 零开销
- **POSIX 平台** (无 `thread_local`): 使用 `pthread_key_create` + `pthread_once` — 延迟初始化线程局部键
- **Windows**: 类似机制

**CurrentTaskQueueSetter** — RAII 模式设置/恢复当前任务队列:
```cpp
{
  TaskQueueBase::CurrentTaskQueueSetter setter(this);
  // 在此作用域内, TaskQueueBase::Current() 返回 this
  DoWork();
  // 析构时自动恢复为 previous_
}
```

**核心虚接口**:
- `PostTask(task)` — 投递一次性任务
- `PostDelayedTask(task, delay)` — 延迟投递
- `PostDelayedHighPrecisionTask(task, delay)` — 高精度延迟任务

---

## 二、PendingTaskSafetyFlag（任务安全标志）

### pending_task_safety_flag.cc
**路径**: `api/task_queue/pending_task_safety_flag.cc`
**关键类**: `PendingTaskSafetyFlag`, `ScopedTaskSafety`

**问题**: 当对象被销毁后，尚未执行的回调可能导致 use-after-free。

**解决方案 — PendingTaskSafetyFlag**:
```cpp
class MyClass {
  ScopedTaskSafety safety_;  // 成员变量
public:
  ~MyClass() {
    // safety_ 析构 → 所有待执行回调的 flag 被标记为 !alive()
  }
  void AsyncOp() {
    task_queue_->PostTask(SafeTask(safety_, [this] {
      // 仅在 MyClass 仍存活时执行
      DoSomething();
    }));
  }
};
```

**`ScopedTaskSafety`**: RAII 包装器。构造时创建 `PendingTaskSafetyFlag`，析构时将 flag 标记为 `!alive()`。

**`SafeTask(flag, callback)`**: 包装回调——先检查 flag 是否 alive，再执行 callback。

---

## 三、平台特定默认工厂

- `default_task_queue_factory_gcd.cc` — macOS/iOS (Grand Central Dispatch)
- `default_task_queue_factory_stdlib.cc` — POSIX (std::thread / libevent)
- `default_task_queue_factory_win.cc` — Windows

---

## 四、TaskQueueTest（任务队列测试）

### task_queue_test.cc
**路径**: `api/task_queue/task_queue_test.cc`

任务队列的兼容性测试套件。所有 TaskQueue 实现必须通过此测试：
- 立即任务投递和执行
- 延迟任务精确性
- 任务顺序保证
- 递归投递 (PostTask from within a task)
- 线程安全性

---

## 学习扩展

### WebRTC 线程模型

```
┌───────────────────────────────────────────────────┐
│               WebRTC 线程体系                       │
│                                                   │
│  信令线程 (Signaling Thread)                       │
│  ├─ PeerConnection 操作 (createOffer/setLocal)     │
│  ├─ SDP 解析和生成                                 │
│  └─ 用户回调                                       │
│                                                   │
│  工作线程 (Worker Thread)                          │
│  ├─ 音频编码/解码                                  │
│  ├─ 视频编码/解码                                  │
│  └─ 音频处理 (APM)                                 │
│                                                   │
│  网络线程 (Network Thread)                         │
│  ├─ ICE/STUN/TURN                                 │
│  ├─ DTLS 握手                                     │
│  ├─ RTP/RTCP 收发                                 │
│  └─ 网络包 I/O                                    │
└───────────────────────────────────────────────────┘
```

### 任务安全模式 (Task Safety Pattern)

```
PostTask(callback) 时:
  创建 SafeTask(token, callback)
  │
  ▼
callback 执行前:
  检查 token->alive()
  ├─ true  → 执行 callback
  └─ false → 跳过 (对象已销毁)
```

### 关键设计模式

| 模式 | 出现位置 | 说明 |
|------|----------|------|
| **RAII** | `CurrentTaskQueueSetter`, `ScopedTaskSafety` | 作用域绑定资源的获取和释放 |
| **Token Pattern** | `PendingTaskSafetyFlag` | 通过令牌控制异步回调安全性 |
| **Thread-Local Storage** | `TaskQueueBase::Current()` | 每线程一组数据 |
| **Factory** | `DefaultTaskQueueFactory*` | 平台适配的任务队列创建 |
| **Template Method** | 测试套件 | 定义通用测试，各实现填充 |
