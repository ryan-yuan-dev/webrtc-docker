# task_queue_base

## 概述

`task_queue_base.h` / `task_queue_base.cc` 定义了 WebRTC 任务队列抽象基类 `TaskQueueBase`。任务队列是 WebRTC 异步编程的核心抽象，提供 FIFO 顺序的任务执行保证（任务不会并发执行），并支持延迟投递。

WebRTC 的线程模型基于多个任务队列，主要分为信令线程、工作线程和网络线程。`TaskQueueBase` 是所有这些线程的底层抽象。

## 头文件接口 (.h)

**文件**: `api/task_queue/task_queue_base.h`

### TaskQueueBase (核心抽象类)

```cpp
class RTC_LOCKABLE RTC_EXPORT TaskQueueBase {
 public:
  enum class DelayPrecision {
    kLow,   // 低精度：最多可增加 17ms 额外延迟
    kHigh,  // 高精度：受 OS 定时器精度限制，无额外延迟
  };

  // 销毁任务队列。确保在返回时无任务执行、无新任务能开始执行。
  virtual void Delete() = 0;

  // 投递一次性任务，FIFO 顺序执行
  void PostTask(absl::AnyInvocable<void() &&> task,
                const Location& location = Location::Current());

  // 低精度延迟投递（推荐优先使用）
  void PostDelayedTask(absl::AnyInvocable<void() &&> task,
                       TimeDelta delay,
                       const Location& location = Location::Current());

  // 高精度延迟投递
  void PostDelayedHighPrecisionTask(absl::AnyInvocable<void() &&> task,
                                     TimeDelta delay,
                                     const Location& location = Location::Current());

  // 根据精度选择 PostDelayedTask 或 PostDelayedHighPrecisionTask
  void PostDelayedTaskWithPrecision(
      DelayPrecision precision,
      absl::AnyInvocable<void() &&> task,
      TimeDelta delay,
      const Location& location = Location::Current());

  // 获取当前线程关联的任务队列
  static TaskQueueBase* Current();
  bool IsCurrent() const;  // Current() == this
};
```

### 关键特征

- `RTC_LOCKABLE`: 标注为可锁对象，配合线程注解使用
- `RTC_EXPORT`: 属于公开 API 层
- 纯虚函数: `Delete()`, `PostTaskImpl()`, `PostDelayedTaskImpl()` 需要子类实现
- 非虚函数: `PostTask()`, `PostDelayedTask()`, `PostDelayedHighPrecisionTask()` 等封装了对纯虚函数的调用

### Delete 语义

```cpp
virtual void Delete() = 0;
```

- 开始销毁任务队列
- 返回时确保：所有运行中的任务已完成，新任务无法开始
- 可能同步或异步释放内存
- 非任务队列所在的线程不应在 Delete 后调用任何方法
- 任务队列所在的线程不应调用 Delete，但可以假设队列仍存在

### PostTask 保证

```cpp
void PostTask(absl::AnyInvocable<void() &&> task,
              const Location& location = Location::Current());
```

- FIFO 顺序执行
- 任务被删除时不会执行，但会被销毁
- 任务销毁时 `Current()` 指向投递该任务的队列 —— 这对 `SequenceChecker` 工作至关重要
- 延迟任务不享此保证

### 延迟精度

```cpp
enum class DelayPrecision {
  kLow,   // 额外延迟: [-1, 17 + OS leeway] ms
  kHigh,  // 额外延迟: [-1, OS leeway] ms
};
```

- `kLow`: 推荐优先使用。17ms 额外延迟的意义是允许系统合并定时器唤醒，减少 CPU 唤醒次数、降低功耗
- `kHigh`: 高精度，无额外延迟但受 OS 定时器精度限制

### CurrentTaskQueueSetter (RAII 辅助类)

```cpp
class RTC_EXPORT CurrentTaskQueueSetter {
 public:
  explicit CurrentTaskQueueSetter(TaskQueueBase* task_queue);
  ~CurrentTaskQueueSetter();
};
```

- RAII 模式：构造时在 TLS 中设置当前任务队列指针，析构时恢复之前的值
- 由子类在执行任务循环时使用

### TaskQueueDeleter

```cpp
struct TaskQueueDeleter {
  void operator()(TaskQueueBase* task_queue) const { task_queue->Delete(); }
};
```

用于 `std::unique_ptr<TaskQueueBase, TaskQueueDeleter>` 智能指针管理生命周期。

## 实现文件 (.cc)

**文件**: `api/task_queue/task_queue_base.cc`

平台相关的 TLS (Thread Local Storage) 实现，有三种路径：

### 路径 1: C++11 thread_local (优先)

```cpp
#if defined(ABSL_HAVE_THREAD_LOCAL)

ABSL_CONST_INIT thread_local TaskQueueBase* current = nullptr;

TaskQueueBase* TaskQueueBase::Current() {
  return current;
}

CurrentTaskQueueSetter::CurrentTaskQueueSetter(TaskQueueBase* task_queue)
    : previous_(current) {
  current = task_queue;
}

CurrentTaskQueueSetter::~CurrentTaskQueueSetter() {
  current = previous_;
}
```

- 使用 `thread_local` 关键字，零开销 TLS 访问
- 存储的是原始指针（不是智能指针），因为任务队列生命周期由使用者管理

### 路径 2: POSIX pthread (备选)

```cpp
#elif defined(WEBRTC_POSIX)

ABSL_CONST_INIT pthread_key_t g_queue_ptr_tls = 0;

void InitializeTls() {
  RTC_CHECK(pthread_key_create(&g_queue_ptr_tls, nullptr) == 0);
}

pthread_key_t GetQueuePtrTls() {
  static pthread_once_t init_once = PTHREAD_ONCE_INIT;
  RTC_CHECK(pthread_once(&init_once, &InitializeTls) == 0);
  return g_queue_ptr_tls;
}

TaskQueueBase* TaskQueueBase::Current() {
  return static_cast<TaskQueueBase*>(pthread_getspecific(GetQueuePtrTls()));
}

CurrentTaskQueueSetter::CurrentTaskQueueSetter(TaskQueueBase* task_queue)
    : previous_(TaskQueueBase::Current()) {
  pthread_setspecific(GetQueuePtrTls(), task_queue);
}

CurrentTaskQueueSetter::~CurrentTaskQueueSetter() {
  pthread_setspecific(GetQueuePtrTls(), previous_);
}
```

- 使用 `pthread_key_t` + `pthread_setspecific`/`pthread_getspecific`
- `pthread_once` 确保 TLS key 只初始化一次（线程安全）

### 路径 3: 其他平台

不支持其他平台，编译时报错 `#error Unsupported platform`。

## 学习扩展

### WebRTC 线程模型

```
信令线程 (Signaling Thread)
├── PeerConnection 操作 (createOffer/setLocalDescription 等)
├── SDP 解析和生成
└── 用户回调 (onIceCandidate, onTrack 等)

工作线程 (Worker Thread)
├── 音频编解码
├── 视频编解码
└── 音频处理 (APM)

网络线程 (Network Thread)
├── ICE/STUN/TURN
├── DTLS 握手
└── RTP/RTCP 收发
```

所有线程都基于 `TaskQueueBase` 抽象。

### 任务生命周期保证

```cpp
void MyClass::PostTaskToQueue() {
  // 任务捕获了 this 指针
  queue_->PostTask([this] {
    // 如果 MyClass 在任务执行前被销毁：
    // use-after-free! 
    DoSomething();
  });
}

// 安全的做法: 使用 ScopedTaskSafety
void MyClass::PostTaskToQueue() {
  queue_->PostTask(SafeTask(safety_.flag(), [this] {
    DoSomething();  // 只有对象仍存活时才执行
  }));
}
```

### 任务销毁时的 Current() 保证

对于非延迟任务，当任务被销毁时（无论是执行后的正常销毁还是删除队列时的批量销毁），`Current()` 都指向投递该任务的任务队列。这意味着：

```cpp
class MyObject {
  SequenceChecker checker_;  // 默认绑定到当前线程
 public:
  MyObject() {
    // checker_ 绑定到构造线程
  }
  
  void PostCleanup(TaskQueueBase* queue) {
    queue->PostTask([this] {
      // 在此执行时:
      // Current() == queue
      // 但 checker_ 可能绑定到不同的线程
      // 需要使用 checker_.Detach() 然后重新绑定
    });
  }
};
```

### 低精度延迟的省电原理

`PostDelayedTask` 的 17ms 额外延迟是 Chrome/Chromium 中使用的一种省电策略：
- 现代 CPU 在空闲时进入低功耗状态 (C-states)
- 从低功耗状态恢复到工作状态有延迟和能量开销
- 合并多个定时器在一个时间点触发，比频繁唤醒 CPU 更节能
- 17ms ≈ 1/60 秒，与常见显示刷新率兼容

## 设计模式

| 模式 | 出现位置 | 说明 |
|------|----------|------|
| **Template Method** | `PostTask` → `PostTaskImpl` | 公共方法封装固定逻辑，纯虚方法由子类实现具体行为 |
| **RAII** | `CurrentTaskQueueSetter` | 作用域内设置当前任务队列，析构时自动恢复 |
| **Thread-Local Storage (TLS)** | `Current()` 实现 | 每线程一个当前任务队列指针 |
| **Abstract Base Class** | `TaskQueueBase` | 定义接口，子类负责平台特定实现 |
| **Pointer-to-Implementation** | `TaskQueueDeleter` | 使用智能指针管理抽象基类的生命周期 |

## 测试: task_queue_test.cc

**文件**: `api/task_queue/task_queue_test.cc`

任务队列的兼容性测试套件，所有 TaskQueue 实现必须通过该测试：

- **立即任务**: PostTask 和任务执行的基本功能
- **延迟任务**: PostDelayedTask 的延迟精确性
- **高精度延迟**: PostDelayedHighPrecisionTask 的精确性
- **FIFO 顺序**: 按序投递的任务按序执行
- **无并发**: 同一队列上的任务不会并发执行
- **递归投递**: 在任务中再投递新任务
- **销毁行为**: Delete 时未执行任务被正确销毁
- **线程安全**: 多线程同时投递

## 测试: default_task_queue_factory_unittest.cc

**文件**: `api/task_queue/default_task_queue_factory_unittest.cc`

测试默认任务队列工厂函数的正确性：
- 工厂函数返回非空指针
- 通过工厂创建的任务队列能正常投递和执行任务
