# jsep_ice_candidate

## 概述

`jsep_ice_candidate.h` / `jsep_ice_candidate.cc` 是 JSEP ICE 候选的旧版接口文件。目前该头文件仅作为向后兼容的转发头，内部 `#include "api/jsep.h"`，将实际定义委托给 `jsep.h`。实现文件 `jsep_ice_candidate.cc` 仍包含 `IceCandidate` 和 `IceCandidateCollection` 的构造函数及关键方法实现。

在 WebRTC 架构中，此文件是重构过渡期的遗留产物，所有新的使用应直接引用 `jsep.h`。

## 头文件接口 (.h)

仅包含一条 `#include "api/jsep.h"` 指令，未定义任何新类型。

## 实现文件 (.cc)

### IceCandidate 构造函数
```cpp
IceCandidate::IceCandidate(sdp_mid, sdp_mline_index, candidate)
```
- 使用 `EnsureValidMLineIndex` 验证 mline_index 范围（0~65535），越界设为 -1。
- 如果 sdp_mid 为空且 sdp_mline_index 为 -1，记录错误日志。

### IceCandidateCollection 实现

| 方法 | 说明 |
|------|------|
| `add(unique_ptr)` | 移动添加候选到 vector |
| `add(raw_ptr)` | 使用 `absl::WrapUnique` 拿所有权后添加 |
| `Append(collection)` | 移动迭代器批量添加 |
| `at(index)` | 返回指定索引的原始指针 |
| `HasCandidate(candidate)` | 使用 `IsEquivalent` 比较，支持按 mid 或 mline_index 匹配 |
| `remove(candidate)` | 使用 `MatchesForRemoval` 查找并移除第一个匹配项 |

### HasCandidate 匹配逻辑
优先使用 `sdp_mid` 进行匹配（如果 sdp_mid 非空），否则使用 `sdp_mline_index` 匹配。

## 学习扩展

- `jsep_ice_candidate.h` 标记为 `TODO: webrtc:406795492 - Delete file once no longer #included.`，表明未来会删除此文件。
- 现有代码如果引用了 `"api/jsep_ice_candidate.h"`，应迁移为直接引用 `"api/jsep.h"`。

## 设计模式

**Facade 适配 (Forwarding Header)**：头文件只负责转发包含，实现仍保留在 `.cc` 中，是 C++ 中逐步废弃接口时的常见迁移模式。
