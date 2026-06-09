# task_queue_test

## 概述

`task_queue_test.cc` 是 WebRTC 任务队列的兼容性测试套件。该测试套件定义了所有 `TaskQueueBase` 实现必须通过的一致性测试，确保不同平台上的任务队列实现行为一致。

## 测试内容

### 基础功能测试

- **PostTask 和立即执行**: 投递简单任务并验证执行
- **PostAndReply**: 从一个任务中投递另一个任务
- **PostDelayedTask**: 延迟任务在指定延迟（或之后）执行
- **PostDelayedHighPrecisionTask**: 高精度延迟任务

### 顺序保证测试

- **FIFO 顺序**: 连续投递的多个任务按投递顺序执行
- **任务无重叠**: 同一队列上的任务不会并发执行
- **嵌套 PostTask**: 在任务中再次调用 PostTask 的正确性
- **PostDelayedTask 后 PostTask**: 延迟和非延迟任务的顺序交互

### 精确性测试

- **PostDelayedTask 延迟下限**: 延迟任务不会早于指定时间执行
- **PostDelayedTask 延迟上限**: 延迟任务在合理时间内执行（不会无限延迟）
- **PostDelayedHighPrecisionTask 精度**: 高精度延迟的定时准确性

### 生命周期测试

- **Delete 行为**: 删除任务队列时，未执行任务的销毁行为
- **PostTask 在 Delete 后**: Delete 后投递任务的行为（不应崩溃）

### 线程安全测试

- **多线程 PostTask**: 多个线程同时向同一队列投递任务
- **跨队列 PostTask**: 从一个队列的任务中向另一个队列投递

### 特殊场景

- **零延迟**: PostDelayedTask 延迟为 0 时等同于 PostTask
- **大延迟**: 发送非常长的延迟（如 1 小时）
- **多次延迟**: 连续投递多个不同延迟的任务
- **任务抛出异常**: 任务抛出异常时队列的稳定性

## 测试用例组织结构

测试套件使用 `TaskQueueTest` 模板类，通过参数化测试在不同实现上运行：

```cpp
class TaskQueueTest : public ::testing::TestWithParam<...> {
 protected:
  std::unique_ptr<TaskQueueBase, TaskQueueDeleter> queue_;
  // 在 SetUp 中根据参数创建对应实现的队列
};

TEST_P(TaskQueueTest, PostTask) {
  // 通用测试逻辑
}

// 注册所有需要测试的实现
INSTANTIATE_TEST_SUITE_P(...);
```

### 测试的队列类型

该测试套件通常会实例化以测试以下所有实现：
1. **stdlib 实现**: Linux/Android 默认
2. **GCD 实现**: macOS/iOS
3. **Windows 实现**: Windows
4. **自定义实现**: 第三方开发者实现的 TaskQueueBase

## 学习扩展

### 为什么需要兼容性测试？

WebRTC 需要运行在多种操作系统和硬件平台上，任务队列的实现根据不同平台的特性而有很大差异：

```cpp
// macOS: 使用 GCD dispatch queue
// 特点: 线程池共享、低功耗定时器

// Linux: 使用 std::thread + 条件变量
// 特点: 1:1 线程模型、POSIX 定时器

// Windows: 使用 Thread Pool API
// 特点: 线程池共享、Windows 定时器队列
```

兼容性测试确保虽然在底层实现不同，但对外表现出完全相同的行为。

### 延迟任务测试技巧

```cpp
// 测试延迟任务精度的典型方法:
// 1. 记录测试开始时间 T1
// 2. 投递一个延迟为 D 的任务
// 3. 在任务中记录执行时间 T2
// 4. 断言 T2 - T1 >= D (不早于)
// 5. 断言 T2 - T1 < D + 允许偏差 (不过晚)

// 需要处理以下问题:
// - 测试环境可能 CPU 负载高
// - 操作系统调度延迟
// - 不同精度等级 (kLow 允许 17ms 额外延迟)
```

### FIFO 顺序测试的关键点

```cpp
// 测试 FIFO 顺序的典型方法:
// 使用原子计数器，每个任务执行时将当前值记录到数组中
// 验证数组中的值是否严格递增

std::atomic<int> counter{0};
std::vector<int> execution_order(5);
for (int i = 0; i < 5; i++) {
  queue_->PostTask([i, &counter, &execution_order] {
    execution_order[i] = ++counter;
  });
}
// 等待所有任务完成
// 验证 execution_order == {1, 2, 3, 4, 5}
```
