# pending_task_safety_flag_unittest

## 概述

`pending_task_safety_flag_unittest.cc` 是 `PendingTaskSafetyFlag` 和 `ScopedTaskSafety` 的单元测试文件。测试覆盖了任务安全标志的核心功能：标志状态的切换、RAII 自动清理、SafeTask 包装、以及多线程场景。

## 测试内容

### PendingTaskSafetyFlag 基本功能

- **创建和状态**: `Create()` 创建的 flag 初始 alive() == true
- **SetNotAlive**: 标记后 alive() 返回 false
- **SetAlive**: 重新标记后 alive() 返回 true
- **多引用**: 多个 scoped_refptr 共享同一个 flag 对象

### ScopedTaskSafety

- **RAII**: ScopedTaskSafety 析构时自动调用 SetNotAlive
- **flag()**: 获取内部 flag 的引用
- **reset()**: 标记旧 flag 为不可用，替换为新 flag
- **拷贝**: ScopedTaskSafety 可以被拷贝，共享 flag 引用

### ScopedTaskSafetyDetached

- **跨线程创建**: 可以在一个线程创建，在另一个线程使用
- **RAII**: 析构时自动标记不可用

### SafeTask

- **正常执行**: flag 为 alive 时，回调正常执行
- **跳过执行**: flag 为 !alive 时，回调被跳过
- **传递性**: SafeTask 包装的回调可被移动和调用
- **SafeInvocable**: 可多次调用的版本

### 多线程场景

- **线程安全的投递**: 在任务队列上投递 SafeTask，确保对象销毁后任务不执行
- **并发安全性**: 多个线程同时访问同一 flag 的正确性
- **Start/Stop/Restart**: ScopedTaskSafety::reset() 的线程安全性

## 代码结构示例

```cpp
TEST(PendingTaskSafetyFlagTest, CreateAlive) {
  auto flag = PendingTaskSafetyFlag::Create();
  EXPECT_TRUE(flag->alive());
}

TEST(PendingTaskSafetyFlagTest, SetNotAlive) {
  auto flag = PendingTaskSafetyFlag::Create();
  flag->SetNotAlive();
  EXPECT_FALSE(flag->alive());
}

TEST(PendingTaskSafetyFlagTest, ScopedTaskSafetyAutoCancel) {
  auto safety = std::make_unique<ScopedTaskSafety>();
  auto flag = safety->flag();
  EXPECT_TRUE(flag->alive());
  safety.reset();  // 析构
  EXPECT_FALSE(flag->alive());
}

TEST(PendingTaskSafetyFlagTest, SafeTaskSkipsWhenNotAlive) {
  auto flag = PendingTaskSafetyFlag::Create();
  flag->SetNotAlive();
  bool executed = false;
  auto task = SafeTask(flag, [&executed] { executed = true; });
  std::move(task)();
  EXPECT_FALSE(executed);
}
```

## 学习扩展

### 测试的关键场景

这些单元测试覆盖了使用 PendingTaskSafetyFlag 时的所有常见错误场景：

```
测试场景 1: 基本生命周期
  flag 创建 → alive() == true
  SetNotAlive() → alive() == false

测试场景 2: RAII 自动管理
  ScopedTaskSafety 创建 → alive() == true
  ScopedTaskSafety 析构 → alive() == false (自动)

测试场景 3: SafeTask 跳过
  PostTask(SafeTask(flag, callback))
  对象析构 → flag.SetNotAlive()
  callback 执行前检查 → flag.alive() == false → 跳过

测试场景 4: Start/Stop/Restart
  safety.reset() → 旧 flag 标记为不可用，创建新 flag
  新任务使用新 flag → 正常执行
```
