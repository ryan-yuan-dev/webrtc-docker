# default_task_queue_factory_unittest

## 概述

`default_task_queue_factory_unittest.cc` 是默认任务队列工厂的单元测试文件。测试验证 `CreateDefaultTaskQueueFactory` 函数返回的工厂能够正常创建功能完整的任务队列。

## 测试内容

### 工厂创建

- 验证 `CreateDefaultTaskQueueFactory(nullptr)` 返回非空指针
- 验证 `CreateDefaultTaskQueueFactory(nullptr)` 返回的工厂可以被正常使用

### 基本任务投递和执行

通过工厂创建任务队列后验证：
- `PostTask` 能够正常投递和执行一次性任务
- 任务按 FIFO 顺序执行
- 任务执行时 `Current()` 返回正确的任务队列

### 延迟任务

- `PostDelayedTask` 在指定延迟后执行
- 延迟任务的执行顺序与投递顺序一致

## 代码结构

```cpp
TEST(DefaultTaskQueueFactoryTest, CreateDefault) {
  auto factory = CreateDefaultTaskQueueFactory(nullptr);
  EXPECT_NE(factory, nullptr);
  
  auto queue = factory->CreateTaskQueue("test", TaskQueueFactory::Priority::NORMAL);
  EXPECT_NE(queue, nullptr);
  
  bool task_executed = false;
  queue->PostTask([&task_executed] { task_executed = true; });
  // ... 
}
```

## 学习扩展

### 跨平台测试

该测试通过编译时的平台选择，在不同平台上使用不同的默认工厂实现：

| 平台 | 实际测试的实现 |
|------|---------------|
| macOS/iOS | GCD 实现 (task_queue_gcd.cc) |
| Linux/POSIX | stdlib 实现 (task_queue_stdlib.cc) |
| Windows | Win 实现 (task_queue_win.cc) |

### TaskQueueFactory 接口

```cpp
class TaskQueueFactory {
 public:
  enum class Priority { NORMAL, HIGH, LOW };
  virtual std::unique_ptr<TaskQueueBase, TaskQueueDeleter>
      CreateTaskQueue(absl::string_view name, Priority priority) = 0;
};
```
