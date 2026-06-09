# field_trials

## 概述

`field_trials.h` / `field_trials.cc` 实现了 `FieldTrials` 类，是 WebRTC 实验性功能开关（Field Trials）的运行时实现。Field Trials 允许 WebRTC 客户端（如 Chromium）在不修改代码的情况下，通过配置字符串在二进制部署中开启/关闭功能特性。

在 WebRTC 架构中，`FieldTrials` 继承自 `FieldTrialsRegistry`，位于 `api/` 层，是各种实验性功能的配置注入点。

## 头文件接口 (.h)

### 类 `FieldTrials`

继承自 `FieldTrialsRegistry`（最终继承自 `FieldTrialsView`）。

| 静态方法 | 说明 |
|---------|------|
| `Create(string_view s)` | 从有效 field trial 字符串创建实例；如果字符串无效返回 nullptr |

| 实例方法 | 说明 |
|---------|------|
| `(constructor)` | 接受 field trial 字符串，非法格式会触发 `RTC_CHECK` 失败 |
| `Merge(const FieldTrials& other)` | 合并另一个 FieldTrials 的配置，冲突时 `other` 优先 |
| `Set(string_view trial, string_view group)` | 设置单个 trial 的 group 值；空 group 表示移除该 trial |
| `CreateCopy()` | 创建当前配置的只读副本（返回 `FieldTrialsView`） |
| `AssertGetValueNotCalled()` | DCHECK 断言尚未执行过 Lookup 操作 |

### Field Trial 字符串格式

```
"WebRTC-ExperimentFoo/Enabled/WebRTC-ExperimentBar/Enabled100kbps/"
```

格式为：`{trial}/{group}/{trial}/{group}/...`，每对 trial/group 以 `/` 分隔。有效字符串必须以 `/` 结尾，否则解析失败。

## 实现文件 (.cc)

### 字符串解析
`Parse()` 函数循环解析 field trial 字符串：
1. 使用 `NextKeyOrValue()` 按 `/` 分隔提取 key 和 value。
2. 如果 key 或 value 为空（例如结尾缺少分隔符），返回 `false`。
3. 重复的 key 但不同 value 视为错误。

### 关键实现细节
- `GetValue()` 在首次调用后会设置 `get_value_called_ = true` 标记，此后对 `Set()`、`Merge()` 的操作会触发 DCHECK。
- `Merge()` 使用 `insert_or_assign`，确保 `other` 中的值覆盖当前值。
- `Set()` 验证 trial 和 group 中不含 `/` 字符，空 group 会从 map 中移除该 trial。
- `CreateCopy()` 通过拷贝构造返回新的 `FieldTrials` 实例。

### flat_map
内部使用 `flat_map<std::string, std::string>`（基于有序 vector 的 map），在数据量较小时性能优于 `std::map`。

## 学习扩展

- Field Trials 的典型用途：控制新功能的 A/B 测试（如新编码器、新拥塞控制算法）。
- FieldTrials 对象一旦被 Lookup 后即变为不可变（immutable），这通过 `get_value_called_` 原子标志强制执行。
- `AbslStringify` 重载提供人类可读的日志输出格式（使用 `//` 而非 `/` 作为分隔符，避免被误解析）。

## 设计模式

**不可变对象 (Immutability)**：首次 Lookup 后冻结配置，防止运行时不一致。

**策略模式 (Strategy)**：FieldTrials 通过注入不同配置改变运行时行为，替代编译时条件编译。
