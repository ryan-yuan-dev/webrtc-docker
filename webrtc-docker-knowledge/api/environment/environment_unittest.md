# environment_unittest

## 概述

`environment_unittest` 是对 `Environment` 和 `EnvironmentFactory` 功能的单元测试。测试覆盖了默认环境创建、自定义工具注入（带/不带所有权）、多个工具叠加、nullptr 忽略、生命周期管理、拷贝语义、工厂复用等核心行为。

## 测试要点

### 测试辅助类
- **`FakeFieldTrials`** — 模拟实现 `FieldTrialsView`，`Lookup()` 始终返回 `"fake"`，支持析构回调。
- **`FakeTaskQueueFactory`** — 模拟实现 `TaskQueueFactory`，`CreateTaskQueue()` 返回 nullptr，支持析构回调。
- **`FakeEvent`** — 模拟实现 `RtcEvent`，类型标记为 `FakeEvent`。
- **`SimulatedClock`** — 使用 WebRTC 提供的模拟时钟。

### 测试用例

| 测试 | 说明 |
|------|------|
| `DefaultEnvironmentHasAllUtilities` | 默认环境所有工具非空，调用时钟、任务队列、事件日志、field trials 不崩溃 |
| `UsesProvidedUtilitiesWithOwnership` | 验证带所有权的工具（unique_ptr）被正确使用，Environment 持有引用而非拷贝 |
| `UsesProvidedUtilitiesWithoutOwnership` | 验证不带所有权的工具（原始指针）被正确使用，引用正确 |
| `UsesLastProvidedUtility` | 多次设置同一类工具时，最后一次设置的优先级最高 |
| `IgnoresProvidedNullptrUtility` | nullptr 工具被静默忽略，之前已设置的工具继续生效 |
| `KeepsUtilityAliveWhileEnvironmentIsAlive` | Environment 存在期间，工具不会被销毁 |
| `KeepsUtilityAliveWhileCopyOfEnvironmentIsAlive` | Environment 拷贝副本存在期间，工具不会被销毁；所有副本销毁后才释放 |
| `FactoryCanBeReusedToCreateDifferentEnvironments` | 工厂可重复使用创建不同环境，之前设置的工具在新环境中保留 |
| `FactoryCanCreateNewEnvironmentFromExistingOne` | 从已有 Environment 构造工厂，新环境与源共享工具 |
| `KeepsOwnershipsWhenCreateNewEnvironmentFromExistingOne` | 从源环境创建新环境时，即使源环境销毁，工具仍存活 |
| `DestroysUtilitiesInReverseProvidedOrder` | 工具以提供顺序的逆序被销毁，符合 C++ 栈展开语义 |
