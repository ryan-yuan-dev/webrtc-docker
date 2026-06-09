# WebRTC 传输层 API 文档

## 概述

`api/transport/` 定义了 WebRTC 传输层的数据结构和网络类型。传输层负责 ICE/STUN/TURN 协议处理、网络拥塞控制和 RTP 包依赖描述。

---

## 一、STUN 协议

### stun.cc
**路径**: `api/transport/stun.cc` (约 49KB)
**关键类**: `StunMessage`, `StunAttribute`, `StunAddressAttribute`, `StunByteStringAttribute`, `StunErrorCodeAttribute`, `StunUInt32Attribute`, `StunUInt64Attribute`, `StunUInt16ListAttribute`

STUN (Session Traversal Utilities for NAT, RFC 8489) 是 WebRTC ICE 协议的基础。此文件实现了完整的 STUN 消息编解码。

**STUN 消息结构**:
```
 0                   1                   2                   3
 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1 2 3 4 5 6 7 8 9 0 1
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|0 0|  STUN Message Type        |         Message Length        |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|                         Magic Cookie                          |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|                                                               |
|                     Transaction ID (96 bits)                  |
|                                                               |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
|                          Attributes                           |
|                             ...                               |
+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+-+
```

**消息类型**:
- `STUN_BINDING_REQUEST` (0x0001) — 绑定请求
- `STUN_BINDING_RESPONSE` (0x0101) — 成功响应
- `STUN_BINDING_ERROR_RESPONSE` (0x0111) — 错误响应

**关键属性**:
| 属性 | 类型 | 说明 |
|------|------|------|
| `MAPPED-ADDRESS` | 0x0001 | 映射后的公网地址 |
| `XOR-MAPPED-ADDRESS` | 0x0020 | XOR 混淆后的映射地址（安全） |
| `USERNAME` | 0x0006 | 认证用户名 |
| `MESSAGE-INTEGRITY` | 0x0008 | HMAC-SHA1 消息完整性校验 |
| `FINGERPRINT` | 0x8028 | CRC32 指纹 |
| `ERROR-CODE` | 0x0009 | 错误码 (300-699) |
| `PRIORITY` | 0x002C | ICE 优先级 |
| `USE-CANDIDATE` | 0x0025 | 提名标志 |
| `ICE-CONTROLLED` | 0x8029 | ICE 受控角色 |
| `ICE-CONTROLLING` | 0x802A | ICE 控制角色 |

**属性长度验证**: `LengthValid()` 对各类属性进行长度校验。USERNAME/REALM/NONCE/SOFTWARE 限制为 508 字节（127 UTF-8 字符 × 4 字节/字符），MESSAGE-INTEGRITY 固定 20 字节（SHA-1）。

**Transaction ID 处理**: `ReduceTransactionId()` 对 96-bit 交易 ID 进行 XOR 折叠生成 32-bit hash，用于统计。

**StunMessage 核心方法**:
- `AddAttribute(attr)` — 添加属性
- `GetAttribute(type)` — 按类型读取属性
- `ValidateMessageIntegrity(password)` — 验证 HMAC-SHA1 签名
- `AddMessageIntegrity(password)` / `AddFingerprint()` — 添加签名和指纹

### stun_unittest.cc
**路径**: `api/transport/stun_unittest.cc` (约 69KB)

全面的 STUN 单元测试。测试覆盖了所有属性类型的编解码、消息序列化/反序列化、完整性校验、错误处理、以及 Google 自定义 STUN 属性。

---

## 二、网络类型

### network_types.cc
**路径**: `api/transport/network_types.cc`
**关键类**: `NetworkControlUpdate`, `TargetRateConstraints`, `TransportPacketsFeedback`, `PacketResult`, `NetworkRouteChange`

定义了发送端带宽估计 (GoogCC) 使用的网络事件和反馈类型。

**核心类型**:
- `TargetRateConstraints` — 目标码率约束 (min/max/start bitrate)
- `TransportPacketsFeedback` — 传输层反馈：发送时间、到达时间、丢包信息
  - `packet_feedbacks[]` — 每个包的 `PacketResult`
  - `data_in_flight` — 在途数据量
- `PacketResult` — 单个包的发送/到达时间戳和大小
- `NetworkRouteChange` — 网络路由变化通知
- `NetworkControlUpdate` — 拥塞控制更新结果（新目标码率、拥塞窗口等）

### bitrate_settings.cc
**路径**: `api/transport/bitrate_settings.cc`
**关键结构**: `BitrateSettings`

码率设置的 simple struct: `start_bitrate_bps`, `min_bitrate_bps`, `max_bitrate_bps`。

### goog_cc_factory.cc
**路径**: `api/transport/goog_cc_factory.cc`
**关键函数**: `CreateGoogCcNetworkControllerFactory()`

创建 Google Congestion Control (GCC/GoogCC) 网络控制器工厂。GoogCC 是 WebRTC 默认的拥塞控制算法（基于延迟+丢包的混合方案）。

---

## 三、RTP 传输扩展

### rtp/dependency_descriptor.cc
**路径**: `api/transport/rtp/dependency_descriptor.cc`
**关键类**: `DependencyDescriptor`

依赖描述符 (Dependency Descriptor) 是 RTP 头扩展，用于描述视频帧之间的解码依赖关系。替代传统的 Frame Marking RTP 头扩展。

**核心概念**:
- **template_id**: 帧依赖模板
- **frame_dependencies**: 当前帧依赖的帧列表
- **decode_target_indications**: 解码目标指示
- **chain_diffs**: 每条可丢弃链的差异数组

**作用**: 使 SFU (Selective Forwarding Unit) 可以在不解析码流的情况下做出准确的帧丢弃决策。

### rtp/corruption_detection_message.cc
**路径**: `api/transport/rtp/corruption_detection_message.cc`
**关键类**: `CorruptionDetectionMessage`

损坏检测消息结构。用于检测 RTP 包在传输过程中是否发生数据损坏。包含 checksum、sequence number mapping 和损坏位图。

---

## 学习扩展

### ICE (Interactive Connectivity Establishment)

```
┌─────────────────────────────────────────────────────────┐
│                     ICE 流程                              │
│                                                         │
│  1. 收集候选者 (Gather Candidates)                        │
│     ├─ host: 本地地址                                     │
│     ├─ srflx: STUN 绑定获取的公网地址                      │
│     └─ relay: TURN 中继地址                               │
│                                                         │
│  2. 交换候选者 (Exchange via SDP)                         │
│                                                         │
│  3. 连通性检查 (Connectivity Checks)                      │
│     ├─ STUN Binding Request/Response                     │
│     └─ 按优先级排序检查                                    │
│                                                         │
│  4. 提名 (Nomination)                                    │
│     └─ 选择最优路径                                       │
└─────────────────────────────────────────────────────────┘
```

### GoogCC 拥塞控制

```
发送端                         网络                    接收端
  │                             │                       │
  ├─ [RTP 包 + TWCC seq] ──────→│                       │
  │                             │                       │
  │                             ├──→ [接收端]            │
  │                             │    记录到达时间        │
  │                             │    ←─ [RTCP Feedback] ┤
  │   ←── [TransportFeedback] ──┤                       │
  │                             │                       │
  ├─ [速率控制器]                │                       │
  │   ├─ 延迟估计 (Trendline)    │                       │
  │   ├─ 丢包检测               │                       │
  │   └─ 码率决策 ──────────────→                       │
  │                             │                       │
```

### 关键设计模式

| 模式 | 出现位置 | 说明 |
|------|----------|------|
| **Serializable** | `StunMessage` | 对象 ↔ 字节流双向转换 |
| **Composite** | `StunMessage` + `StunAttribute` | 消息包含多个属性 |
| **Factory Method** | `CreateGoogCcNetworkControllerFactory` | 创建 GoogCC 工厂 |
| **Observer** | `NetworkControlUpdate` | 拥塞控制事件通知 |
