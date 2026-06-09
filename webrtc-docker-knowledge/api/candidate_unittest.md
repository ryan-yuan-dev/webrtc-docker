# candidate_unittest

## 概述

`candidate_unittest.cc` 是对 `api/candidate.h` 中 `Candidate` 类的单元测试文件。

## 测试范围

- `Candidate` 默认构造和参数构造
- 类型检查方法：`is_local()`、`is_stun()`、`is_prflx()`、`is_relay()`
- `type_name()` 的字符串表示
- `IsEquivalent()` 等价比较（忽略 network_name、priority、network_cost）
- `MatchesForRemoval()` 移除匹配
- `operator==` / `operator!=`
- `ToSanitizedCopy()` 脱敏副本（IP 过滤、related_address 过滤、ufrag 过滤）
- `ComputeFoundation()` foundation 计算
- `ComputePrflxFoundation()` prflx 特殊 foundation 计算
- `GetPriority()` 优先级算法
- `ToString()` / `ToSensitiveString()` 序列化
- `ToCandidateAttribute()` SDP 属性格式输出
