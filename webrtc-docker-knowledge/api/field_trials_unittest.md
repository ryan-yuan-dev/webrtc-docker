# field_trials_unittest

## 概述

`field_trials_unittest.cc` 是对 `api/field_trials.h` 中 `FieldTrials` 类的单元测试文件。

## 测试范围

- 有效的 field trial 字符串解析（正确格式）
- 无效字符串的解析失败（缺少结尾分隔符、空 key/value）
- 重复 trial 的检测
- `Merge()` 合并行为
- `Set()` 设置单个 trial
- `CreateCopy()` 拷贝创建
- 通过 `Lookup()` 查询值
- 冲突时的覆盖语义
- 空 group 的移除行为
- `AssertGetValueNotCalled()` 断言
- `AbslStringify()` 格式化输出
