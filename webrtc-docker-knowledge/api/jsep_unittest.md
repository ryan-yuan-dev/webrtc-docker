# jsep_unittest

## 概述

`jsep_unittest.cc` 是对 `api/jsep.h` 中 JSEP 相关类的单元测试文件，主要测试 `IceCandidate`、`IceCandidateCollection` 和 `SessionDescriptionInterface`。

## 测试范围

- `IceCandidate::Create()` 从 SDP 字符串解析
- `IceCandidate::ToString()` 序列化
- `IceCandidate::sdp_mid()` / `sdp_mline_index()` 属性
- `IceCandidateCollection::add()` / `at()` / `count()` 集合操作
- `IceCandidateCollection::HasCandidate()` 等价检查
- `IceCandidateCollection::remove()` 移除匹配
- `IceCandidateCollection::Clone()` 深拷贝
- `SessionDescriptionInterface::Create()` 工厂方法
- `CreateSessionDescription()` 从 SDP 文本创建
- SdpType 的 `ToString` 和 `FromString` 转换
- `CreateRollbackSessionDescription()`
- `SessionDescriptionInterface::AddCandidate()` / `RemoveCandidate()`
- `SessionDescriptionInterface::ToString()` 序列化
