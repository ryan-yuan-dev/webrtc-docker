# candidate

## 概述

`candidate.h` / `candidate.cc` 定义了 `Candidate` 类，表示一个 ICE (Interactive Connectivity Establishment) 连接候选项。该结构是 WebRTC 连接建立过程中网络发现的基石，封装了 IP 地址、端口、协议、类型等关键信息。

在 WebRTC 架构中，`Candidate` 位于 `api/` 层，被 `p2p/` 层使用，并通过 `jsep.h` 中的 `IceCandidate` 暴露给上层应用。它对应 RFC 5245 中定义的 candidate-attribute。

## 头文件接口 (.h)

### 枚举 `IceCandidateType`

| 值 | 说明 |
|----|------|
| `kHost` | 本地主机候选（LAN 地址） |
| `kSrflx` | Server Reflexive 候选（经 STUN 服务器反射获知的公网地址） |
| `kPrflx` | Peer Reflexive 候选（通过对端发送的连通性检查动态发现） |
| `kRelay` | 中继候选（经 TURN 服务器转发） |

### 类 `Candidate`

| 属性与方法 | 类型/返回 | 说明 |
|-----------|-----------|------|
| `id()` / `generate_id()` | `const string&` | 8 字符随机 ID，用于日志追踪 |
| `component()` | `int` | 组件 ID（RTP=1, RTCP=2） |
| `protocol()` | `string` | 传输协议（UDP/TCP/SSLTCP/TLS） |
| `relay_protocol()` | `string` | 与中继通信的协议 |
| `address()` | `SocketAddress` | 候选的 IP 地址和端口 |
| `priority()` | `uint32_t` | 优先级，决定 ICE 候选排序 |
| `username()` / `password()` | `string` | ICE 凭据，用于 STUN 连通性检查 |
| `type()` / `type_name()` | `IceCandidateType` / `string` | 候选项类型 |
| `is_local()` / `is_stun()` / `is_prflx()` / `is_relay()` | `bool` | 类型快捷检查 |
| `type_preference()` | `int` | 类型偏好值 (1=host, 2=srflx, 3=relay) |
| `network_name()` | `string` | 网络接口名称（调试信息） |
| `network_type()` | `AdapterType` | 网络适配器类型（WiFi/蜂窝/以太网等） |
| `generation()` | `uint32_t` | 候选代次，新一代替换旧代 |
| `network_cost()` | `uint16_t` | 网络成本（0=可自由使用） |
| `network_id()` | `uint16_t` | 网络接口 ID |
| `foundation()` | `string` | 相同类型/基础 IP/协议的候选共享相同 foundation |
| `related_address()` | `SocketAddress` | 相关地址（如被反射地址） |
| `tcptype()` | `string` | TCP 类型（active/passive/so） |
| `url()` | `string` | 获取该候选的 ICE 服务器 URL |
| `IsEquivalent()` | `bool` | 判断两个候选项是否等价（忽略名称/优先级/成本） |
| `MatchesForRemoval()` | `bool` | 判断是否匹配移除条件（仅比较 component/protocol/address） |
| `ComputeFoundation()` | `void` | 计算 foundation 值（基于类型/基础地址/协议/tie-breaker 的 CRC32） |
| `ComputePrflxFoundation()` | `void` | 为 prflx 候选计算 foundation |
| `ToCandidateAttribute()` | `string` | 生成 RFC 5245 Section 15.1 格式的 candidate 属性 |
| `GetPriority()` | `uint32_t` | 根据 RFC 5245 4.1.2.1 计算优先级 |
| `ToSanitizedCopy()` | `Candidate` | 生成脱敏副本（可过滤 IP/related_address/ufrag） |

### 常量

| 常量 | 值 | 说明 |
|------|-----|------|
| `kMaxTurnServers` | `32` | TURN 服务器数量上限（W3C 规范要求） |
| `LOCAL_PORT_TYPE` (deprecated) | `"local"` | 旧版 host 类型字符串，使用 `IceCandidateType` 替代 |
| `STUN_PORT_TYPE` (deprecated) | `"stun"` | 旧版 srflx 类型字符串，使用 `IceCandidateType` 替代 |
| `PRFLX_PORT_TYPE` (deprecated) | `"prflx"` | 旧版 prflx 类型字符串，使用 `IceCandidateType` 替代 |
| `RELAY_PORT_TYPE` (deprecated) | `"relay"` | 旧版 relay 类型字符串，使用 `IceCandidateType` 替代 |

## 实现文件 (.cc)

### 构造函数
- 默认构造：生成 8 字符随机 ID，`component_` 默认为 `ICE_CANDIDATE_COMPONENT_DEFAULT`
- 带参构造：完整初始化候选，也生成随机 ID

### GetPriority 算法
根据 RFC 5245 Section 4.1.2.1：
```
priority = (2^24) * type_preference + (2^8) * local_preference + (256 - component)
```
其中 `local_preference = (NIC_Pref << 8 | Addr_Pref) + relay_preference`，NIC Pref 是网络适配器偏好，Addr Pref 是 IP 地址偏好（RFC 3484）。通过添加 `kMaxTurnServers` 确保 relay 候选的 STUN 优先级不会高于 server-reflexive。

### ComputeFoundation
将 type_name + base IP + protocol + relay_protocol + tie_breaker 拼接后计算 CRC32，确保相同类型、相同基础地址和协议的候选共享 foundation。

### ToSanitizedCopy
用于隐私保护，可以：
- 使用主机名替换 IP 地址
- 清空 related_address
- 过滤 ufrag

## 学习扩展

- ICE 候选类型优先级：按照 RFC 5245 建议，为避免连通性故障，推荐 `relayed > reflexive > host`
- `Candidate::GetPriority` 中的 `adjust_local_preference` 参数确保特定情况下 STUN 优先级的正确性
- `ToCandidateAttribute()` 生成的字符串与 SDP 中的 `a=candidate:` 行对应

## 设计模式

**值对象模式 (Value Object)**：`Candidate` 是不可变/半可变的值对象，提供丰富的比较、转换和序列化方法。其构造函数通过初始化列表保证了创建时的一致状态。

**建造者模式变体**：通过 setter 方法链逐步构建候选项，构造函数提供完整初始化路径。
