# field_trials_registry

## 概述

`field_trials_registry.h` / `field_trials_registry.cc` 定义了 `FieldTrialsRegistry` 抽象基类。它在 `FieldTrialsView` 的基础上增加了 key 预注册验证功能，确保只有预先注册过的 field trial key 被合法查询，防止拼写错误或未注册的 experiment 被误用。

在 WebRTC 架构中，`FieldTrialsRegistry` 是 `FieldTrialsView` 和具体 `FieldTrials` 实现之间的中间抽象层，位于 `api/` 层。

## 头文件接口 (.h)

### 类 `FieldTrialsRegistry`

继承自 `FieldTrialsView`。

| 方法 | 说明 |
|------|------|
| `Lookup(string_view key)` | 查询 key 的值，执行前先验证 key 是否已注册 |
| `RegisterKeysForTesting(flat_set<string>)` | (仅测试用) 注册虚拟 key，避免 DCHECK 失败 |

### 抽象方法（子类必须实现）

| 方法 | 说明 |
|------|------|
| `GetValue(string_view key)` | 返回 key 对应的值，空字符串表示未配置 |

## 实现文件 (.cc)

### Lookup 实现
Lookup 实现了两级验证机制，由编译标志 `WEBRTC_STRICT_FIELD_TRIALS` 控制：

- `WEBRTC_STRICT_FIELD_TRIALS == 1`：严格模式。DCHECK 验证 key 是否在 `kRegisteredFieldTrials` 数组或 `test_keys_` 中。不满足则崩溃。
- `WEBRTC_STRICT_FIELD_TRIALS == 2`：警告模式。仅 LOG WARNING 提示 key 未注册。
- 未定义或为 0：跳过验证，直接返回 `GetValue(key)`。

验证后调用纯虚函数 `GetValue(key)` 获取实际值。

## 学习扩展

- `kRegisteredFieldTrials` 定义在 `experiments/registered_field_trials.h` 中，由构建系统自动生成，包含所有官方注册的 field trial key。
- 该注册机制确保 field trial 名称的一致性和可发现性，详见 `g3doc/field-trials.md`。
- 测试中需要使用 `RegisterKeysForTesting` 注册虚拟 key，否则 Lookup 会触发 DCHECK。

## 设计模式

**模板方法 (Template Method)**：`Lookup` 是公开的模板方法，定义了"验证-查询"的算法骨架，而 `GetValue` 是子类提供的具体实现。

**抽象基类 (Abstract Base Class)**：定义接口契约，子类 `FieldTrials` 提供具体实现。
