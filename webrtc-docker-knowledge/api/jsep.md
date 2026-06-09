# jsep

## 概述

`jsep.h` / `jsep.cc` 定义了 WebRTC JSEP (JavaScript Session Establishment Protocol) 相关的核心类型，包括 `IceCandidate`、`IceCandidateCollection`、`SessionDescriptionInterface` 以及 SDP 创建/设置的观察者接口。这些类型包装了底层 SDP 和 ICE 候选的数据结构，是应用程序与 PeerConnection 之间信令交互的桥梁。

在 WebRTC 架构中，该文件位于 `api/` 层，是 PeerConnection 信令过程中的核心数据结构。

## 头文件接口 (.h)

### 结构体 `SdpParseError`

| 成员 | 类型 | 说明 |
|------|------|------|
| `line` | `string` | 导致错误的 SDP 行 |
| `description` | `string` | 错误描述 |

### 类 `IceCandidate`
表示一个 ICE 候选（JSEP 规范），与底层的 `Candidate` 类配合使用：

| 方法 | 说明 |
|------|------|
| `Create(mid, mline_index, sdp, error)` | 从 SDP 字符串解析创建 |
| `sdp_mid()` | 候选所属 m= section 的 mid 值 |
| `sdp_mline_index()` | 候选所属 m= section 的索引 |
| `candidate()` | 底层的 `Candidate` 对象 |
| `server_url()` | 获取该候选的 ICE 服务器 URL |
| `ToString()` | 序列化为 SDP 字符串 |

别名：`JsepIceCandidate`、`IceCandidateInterface`（为向后兼容保留）。

### 类 `IceCandidateCollection`
管理某个 m= section 的所有候选集合：

| 方法 | 说明 |
|------|------|
| `count()` / `empty()` | 集合大小 |
| `at(index)` | 按索引访问 |
| `add(unique_ptr)` / `add(raw_ptr)` | 添加候选（持有所有权） |
| `Append(collection)` | 合并另一个集合 |
| `remove(candidate)` | 移除匹配的候选（地址+协议） |
| `HasCandidate(candidate)` | 判断等价候选是否存在 |
| `Clone()` | 深度拷贝 |

别名：`JsepCandidateCollection`。

### 枚举 `SdpType`

| 值 | 说明 |
|----|------|
| `kOffer` | SDP Offer |
| `kPrAnswer` | SDP Provisional Answer（最终 answer 之前的临时回复） |
| `kAnswer` | SDP Final Answer |
| `kRollback` | 回滚，重置 pending offer 到 stable |

### 类 `SessionDescriptionInterface`（继承自 `SessionDescriptionInternal`）

| 方法 | 说明 |
|------|------|
| `Create(type, desc, id, version, candidates)` | 静态工厂方法 |
| `Clone()` | 深拷贝 |
| `description()` | 访问内部的 `SessionDescription` |
| `session_id()` / `session_version()` | 会话 ID 和版本（来自 SDP o= 行） |
| `GetType()` / `type()` | 获取 SDP 类型 |
| `AddCandidate(candidate)` | 添加候选到对应 m= section |
| `RemoveCandidate(candidate)` | 移除候选 |
| `number_of_mediasections()` | m= section 数量 |
| `candidates(mediasection_index)` | 获取指定 m= section 的候选集合 |
| `ToString()` | 序列化为完整 SDP 文本 |

### 全局工厂函数

| 函数 | 说明 |
|------|------|
| `CreateIceCandidate(mid, mline, sdp, error)` | 从 SDP 字符串创建 IceCandidate |
| `CreateIceCandidate(mid, mline, candidate)` | 从 Candidate 对象创建 IceCandidate |
| `CreateSessionDescription(type, sdp)` | 从 SDP 字符串创建 SessionDescription |
| `CreateSessionDescription(type, sdp, error)` | 同上，带错误输出 |
| `CreateSessionDescription(type, id, version, desc)` | 从内部结构创建 |
| `CreateRollbackSessionDescription(id, version)` | 创建回滚描述 |

### 观察者接口

| 接口 | 回调 |
|------|------|
| `CreateSessionDescriptionObserver` | `OnSuccess(SessionDescriptionInterface*)`, `OnFailure(RTCError)` |
| `SetSessionDescriptionObserver` | `OnSuccess()`, `OnFailure(RTCError)` |

### `SessionDescriptionInternal`
提供受保护的线程感知基类，管理 `SdpType`、会话 id/version、内部的 `SessionDescription` 指针以及 `SequenceChecker`。提供 `RelinquishThreadOwnership()` 方法用于跨线程所有权转移。

## 实现文件 (.cc)

### SdpType 字符串转换
```cpp
SdpTypeToString(SdpType)    // kOffer -> "offer", kAnswer -> "answer" ...
SdpTypeFromString(string)   // "offer" -> kOffer, "pranswer" -> kPrAnswer ...
```

## 学习扩展

- JSEP（RFC 8829）定义了 Offer/Answer 协议在 WebRTC 中的应用方式，将信令状态机抽象为 `SdpType` 枚举。
- `IceCandidate` 是 `Candidate` 的 SDP 包装层，添加了 mid 和 mline_index 属性用于 SDP 解析/生成。
- `SessionDescriptionInterface` 正在从纯虚接口向非虚具体类迁移，`SessionDescriptionInternal` 是过渡期的中间层。
- `CreateSessionDescriptionObserver` 和 `SetSessionDescriptionObserver` 都是 `RefCountInterface`，通过引用计数管理生命周期。

## 设计模式

**不可变对象 (Immutable Object)**：`IceCandidate` 的 sdp_mid、sdp_mline_index 和 candidate 在构造后不可变。

**工厂方法 (Factory Method)**：使用静态工厂方法（`IceCandidate::Create`、`SessionDescriptionInterface::Create`）替代构造函数。

**观察者模式 (Observer)**：`CreateSessionDescriptionObserver` 和 `SetSessionDescriptionObserver` 用于异步结果通知。

**组合模式 (Composite)**：`IceCandidateCollection` 组合多个 `IceCandidate`，提供集合操作。
