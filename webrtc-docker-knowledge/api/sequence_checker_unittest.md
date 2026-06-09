# sequence_checker_unittest

## 概述

`sequence_checker_unittest.cc` 是对 `api/sequence_checker.h` 中 `SequenceChecker` 类的单元测试文件。`SequenceChecker` 是 WebRTC 的线程安全检查工具，用于验证函数是否在预期的线程或任务队列上执行，在 Debug 构建中通过 DCHECK 进行断言。

## 测试范围

- 默认构造（detached 状态）
- 单线程上的连续调用检测
- 跨线程访问检测（应触发 DCHECK）
- `IsCurrent()` 判断
- `Detach()` 分离后在新线程上附加
- 与 TaskQueue 的集成
- 与 `RTC_GUARDED_BY` 注解的配合使用
- 拷贝和移动语义对 checker 状态的影响
- 在 PlatformThread 上的行为
- `RTC_DCHECK_RUN_ON` 宏的测试
