# pending_task_safety_flag

## 概述

`pending_task_safety_flag.h` / `pending_task_safety_flag.cc` 实现了 WebRTC 的任务安全机制，用于解决异步编程中的 use-after-free 问题。当对象被销毁后，其已投递但尚未执行的回调如果不加处理地继续执行，将导致野指针访问已释放内存。

核心思路是通过一个引用计数的安全标志 (flag)，在对象销毁时将 flag 标记为"不可用"，所有待执行或新投递的回调在执行前检查该标志，若标志为不可用则跳过执行。

## 头文件接口 (.h)

**文件**: `api/task_queue/pending_task_safety_flag.h`

### PendingTaskSafetyFlag (核心标志类)

```cpp
class RTC_EXPORT PendingTaskSafetyFlag final
    : public RefCountedNonVirtual<PendingTaskSafetyFlag> {
 public:
  static scoped_refptr<PendingTaskSafetyFlag> Create();
  static scoped_refptr<PendingTaskSafetyFlag> CreateDetached();
  static scoped_refptr<PendingTaskSafetyFlag> CreateAttachedToTaskQueue(
      bool alive, TaskQueueBase* attached_queue);
  static scoped_refptr<PendingTaskSafetyFlag> CreateDetachedInactive();

  void SetNotAlive();    // 标记为不可用
  void SetAlive();       // 重新标记为可用（支持 Start/Stop/Restart 场景）
  bool alive() const;    // 检查是否可用
};
```

四种创建方式：

| 工厂方法 | 初始 alive | SequenceChecker | 用途 |
|----------|-----------|----------------|------|
| `Create()` | true | 初始化 | 标准用法，创建和使用在同一线程 |
| `CreateDetached()` | true | detached | 创建线程与使用线程不同 |
| `CreateAttachedToTaskQueue(alive, queue)` | 指定值 | 绑定到指定队列 | 显式控制初始状态和关联队列 |
| `CreateDetachedInactive()` | false | detached | 初始即不活跃，用于延迟激活场景 |

### ScopedTaskSafety (RAII 包装器)

```cpp
class RTC_EXPORT ScopedTaskSafety final {
 public:
  ScopedTaskSafety();
  explicit ScopedTaskSafety(scoped_refptr<PendingTaskSafetyFlag> flag);
  ~ScopedTaskSafety();  // 析构时自动调用 flag_->SetNotAlive()

  scoped_refptr<PendingTaskSafetyFlag> flag() const;
  void reset(scoped_refptr<PendingTaskSafetyFlag> new_flag =
                 PendingTaskSafetyFlag::Create());
};
```

典型的 RAII 使用模式：

```cpp
class MyClass {
  ScopedTaskSafety safety_;  // 声明为成员变量
 public:
  ~MyClass() {
    // safety_ 析构 → 自动标记 flag 为 !alive()
    // 无需手动调用
  }
};
```

### ScopedTaskSafetyDetached

```cpp
class RTC_EXPORT ScopedTaskSafetyDetached final {
 public:
  ScopedTaskSafetyDetached();  // 使用 CreateDetached() 创建内部 flag
  ~ScopedTaskSafetyDetached(); // 析构时标记不可用
  scoped_refptr<PendingTaskSafetyFlag> flag() const;
};
```

- 用于跨线程创建和使用的场景
- 内部使用 `CreateDetached()` 创建 flag，SequenceChecker 初始为 detached 状态

### SafeTask (辅助函数)

```cpp
inline absl::AnyInvocable<void() &&> SafeTask(
    scoped_refptr<PendingTaskSafetyFlag> flag,
    absl::AnyInvocable<void() &&> task) {
  return [flag = std::move(flag), task = std::move(task)]() mutable {
    if (flag->alive()) {
      std::move(task)();
    }
  };
}

inline absl::AnyInvocable<void()> SafeInvocable(
    scoped_refptr<PendingTaskSafetyFlag> flag,
    absl::AnyInvocable<void()> task) {
  return [flag = std::move(flag), task = std::move(task)]() mutable {
    if (flag->alive()) {
      task();
    }
  };
}
```

- `SafeTask`: 包装一次性回调 (&&)，执行前检查 flag
- `SafeInvocable`: 包装可多次调用的回调 (&)，同样执行前检查 flag

## 实现文件 (.cc)

**文件**: `api/task_queue/pending_task_safety_flag.cc`

### 工厂方法实现

```cpp
scoped_refptr<PendingTaskSafetyFlag> PendingTaskSafetyFlag::CreateDetached() {
  auto flag = CreateInternal(true);
  flag->main_sequence_.Detach();  // 分离 SequenceChecker
  return flag;
}

scoped_refptr<PendingTaskSafetyFlag>
PendingTaskSafetyFlag::CreateAttachedToTaskQueue(bool alive,
                                                 TaskQueueBase* attached_queue) {
  RTC_DCHECK(attached_queue) << "Null TaskQueue provided";
  return scoped_refptr<PendingTaskSafetyFlag>(
      new PendingTaskSafetyFlag(alive, attached_queue));
}
```

### alive 和 SetNotAlive

```cpp
void PendingTaskSafetyFlag::SetNotAlive() {
  RTC_DCHECK_RUN_ON(&main_sequence_);  // 必须在关联线程调用
  alive_ = false;
}

void PendingTaskSafetyFlag::SetAlive() {
  RTC_DCHECK_RUN_ON(&main_sequence_);  // 必须在关联线程调用
  alive_ = true;
}

bool PendingTaskSafetyFlag::alive() const {
  RTC_DCHECK_RUN_ON(&main_sequence_);  // 必须在关联线程调用
  return alive_;
}
```

- 所有 `alive_` 的读写都受 `RTC_DCHECK_RUN_ON` 保护，确保线程安全性
- `SetAlive()` 和 `SetNotAlive()` 的成对使用支持 Start/Stop/Restart 模式
- `alive_` 读取只在关联线程上执行（但 flag 的拷贝可以在任何线程持有）

## 学习扩展

### 任务安全问题场景

```
场景: 类对象在回调执行前被销毁

线程 A (任务队列)             线程 B (用户)
     │                          │
     │ ← PostTask(callback)     │
     │                          ├── ~MyClass()  // 对象销毁
     │                          │
     │ → callback 执行          │
     │   this->DoSomething()    │  ← BUG! this 已释放
     │                          │

解决方案: 使用 PendingTaskSafetyFlag

     │ ← PostTask(SafeTask(flag, callback))
     │                          ├── ~MyClass ()
     │                          │   safety_ 析构 → flag.SetNotAlive()
     │ → SafeTask 执行          │
     │   if (flag->alive()) {   │  ← false, 跳过执行
     │     callback()           │  ← 不会执行
     │   }                      │
```

### Start/Stop/Restart 模式

```cpp
class CameraModule {
  ScopedTaskSafety safety_;
 public:
  void Start() {
    safety_.reset();  // 旧 flag SetNotAlive, 创建新 flag
    task_queue_->PostTask(SafeTask(safety_.flag(), [this] { ... }));
  }

  void Stop() {
    safety_.reset(PendingTaskSafetyFlag::CreateDetachedInactive());
  }
};
```

使用 `reset()` 方法可以循环利用 `ScopedTaskSafety`，同时确保旧任务被取消、新任务使用新 flag。

### ScopedTaskSafety 和 ScopedTaskSafetyDetached 的区别

| 特性 | ScopedTaskSafety | ScopedTaskSafetyDetached |
|------|-----------------|--------------------------|
| 内部 flag 创建 | `Create()` | `CreateDetached()` |
| 线程约束 | 创建/销毁与使用必须同一线程 | 允许跨线程创建和销毁 |
| SequenceChecker | 初始绑定 | 初始 detached |
| 典型用途 | 任务队列内的对象 | 跨线程传递的对象 |

### 引用计数

`PendingTaskSafetyFlag` 继承自 `RefCountedNonVirtual`，使用 `scoped_refptr` 管理生命周期：

```cpp
auto flag = PendingTaskSafetyFlag::Create();
// flag 引用计数 = 1

auto flag_copy = flag;
// flag 引用计数 = 2

// flag 和 flag_copy 都析构后，对象自动释放
```

## 设计模式

| 模式 | 出现位置 | 说明 |
|------|----------|------|
| **RAII** | `ScopedTaskSafety`, `ScopedTaskSafetyDetached` | 资源获取即初始化，析构时自动清理 |
| **Token Pattern** | `PendingTaskSafetyFlag` | 通过令牌控制异步回调的安全性，而不是直接管理对象生命周期 |
| **Reference Counting** | `RefCountedNonVirtual` + `scoped_refptr` | 通过引用计数管理共享资源生命周期 |
| **Decorator/Wrapper** | `SafeTask()`, `SafeInvocable()` | 为原始回调添加安全检查层，不修改原始回调逻辑 |
| **Guarded Object** | `RTC_DCHECK_RUN_ON(&main_sequence_)` | 通过 SequenceChecker 确保线程安全访问 |

## 测试: pending_task_safety_flag_unittest.cc

单元测试覆盖：
- PendingTaskSafetyFlag 的基本 alive/SetNotAlive 行为
- ScopedTaskSafety 在析构时自动标记不可用
- SafeTask 在 flag 不可用时跳过执行
- 多线程场景下的安全性
- Start/Stop/Restart 模式
- CreateDetached 跨线程使用
