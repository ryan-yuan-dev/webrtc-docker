# deprecated_global_field_trials

## 概述

`deprecated_global_field_trials` 模块提供了一种已废弃的全局 Field Trials 机制。Field Trials 是 WebRTC 用于 A/B 测试和功能开关的字符串配置系统。该类通过全局静态变量存储 field trial 字符串，被标记为已废弃（计划于 2026 年 1 月 1 日后删除），新代码应使用 `Environment` 和 `EnvironmentFactory` 提供的可组合 Field Trials 方案。

## 头文件接口 (.h)

### `DeprecatedGlobalFieldTrials` 类

继承自 `FieldTrialsRegistry`：

- **`Set(const char* field_trials)`** — 静态方法，设置全局 field trial 字符串。
- **`CreateCopy()`** — 创建当前对象的拷贝，用于传递到其他组件。
- **`GetValue(absl::string_view key)`** — 私有实现方法，从存储的全局字符串中查找指定 key 对应的 value。

## 实现文件 (.cc)

### 关键实现逻辑

**全局变量 `global_field_trial_string`**:
- 使用 `constinit` 关键字声明的模块内部静态指针，初始化为 `nullptr`。
- `constinit` 确保该变量在静态初始化顺序问题中不会出现动态初始化失败。

**`Set()` 方法**: 将传入的 C 字符串指针赋值给全局静态变量。注意这仅仅是保存指针，不拷贝字符串内容，调用者需确保字符串在整个生命周期有效。

**`GetValue()` 方法**:
1. 检查全局字符串指针是否为 `nullptr`，如果是则返回空字符串。
2. 如果全局字符串为空，返回空字符串。
3. 遍历 field trial 字符串，格式为 `key1/value1/key2/value2/...`，通过查找 `/` 分隔符解析键值对。
4. 找到匹配的 key 后返回对应的 value，否则返回空字符串。

### 设计缺陷

- **全局状态**: 使用全局变量，不适用于需要不同配置的多个 PeerConnection 实例。
- **线程安全**: 无同步保护，在多线程环境中存在数据竞争风险。
- **生命周期**: 仅保存指针而非拷贝，调用者需自行管理字符串生命周期。

## 学习扩展

- **Field Trials 格式**: WebRTC 的 field trial 采用 `Key/Value/Key/Value/` 的 URI 风格格式，使用 `/` 分隔键和值。
- **constinit vs constexpr**: C++20 引入的 `constinit` 保证变量在静态初始化阶段完成初始化，避免 "static initialization order fiasco"。
- **FieldTrialsView vs FieldTrialsRegistry**: `FieldTrialsView` 是只读接口，`FieldTrialsRegistry` 在其基础上增加了动态查找和复制的功能。

## 设计模式

- **单例模式（有缺陷）** — 全局静态变量配合静态 `Set` 方法实现类似单例的全局访问点。
- **策略模式** — 通过虚函数 `GetValue` / `Lookup` 将 field trial 查找策略抽象化，允许不同实现。
