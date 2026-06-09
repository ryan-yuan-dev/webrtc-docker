# priority

## 概述

`priority.h` / `priority.cc` 定义了 WebRTC 中优先级相关的类型，包括 `Priority` 枚举和 `PriorityValue` 类型。优先级用于 DataChannel 和 RTP stream 的带宽分配及 QoS 标记。

在 WebRTC 架构中，该文件位于 `api/` 层，被 `data_channel_interface.h` 和 `rtp_parameters.h` 引用。

## 头文件接口 (.h)

### 枚举 `Priority`

| 值 | 说明 |
|----|------|
| `kVeryLow` | 非常低 |
| `kLow` | 低 |
| `kMedium` | 中 |
| `kHigh` | 高 |

### 类 `PriorityValue`
基于 `StrongAlias<uint16_t>` 的强类型包装：

- `PriorityValue(Priority priority)`：从枚举构造，映射为对应的数值。
- `PriorityValue(uint16_t priority)`：从原始数值构造。

## 实现文件 (.cc)

### 优先级数值映射

| Priority 枚举 | 对应 uint16_t 值 |
|--------------|-----------------|
| `kVeryLow` | 128 |
| `kLow` | 256 |
| `kMedium` | 512 |
| `kHigh` | 1024 |

映射关系为 2 的幂次增长（128 = 2^7, 256 = 2^8, 512 = 2^9, 1024 = 2^10）。

## 学习扩展

- `PriorityValue` 使用 `StrongAlias` 模板进行强类型包装，防止原始 uint16_t 被错误用于期望 `PriorityValue` 的上下文。
- WebRTC 标准中的优先级字段（W3C `RTCRtpEncodingParameters.priority` 和 `RTCDataChannelInit.priority`）使用"very-low"、"low"、"medium"、"high" 字符串表示。
- 在 DataChannel 中，优先级影响 SCTP 流的调度顺序。在 RTP sender 中，优先级影响 DSCP 标记和带宽分配。

## 设计模式

**强类型别名 (Strong Typedef)**：通过 `StrongAlias` 模板创建 `PriorityValue` 类型，提供编译期类型安全。

**值对象 (Value Object)**：`PriorityValue` 是不可变的值类型，封装了优先级到数值的映射关系。
