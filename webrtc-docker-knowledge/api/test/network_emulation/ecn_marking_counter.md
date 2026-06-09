# ecn_marking_counter

## 概述

`EcnMarkingCounter` 是一个简单的 ECN（Explicit Congestion Notification，显式拥塞通知）标记计数器，用于统计 IP 包中不同 ECN 标记的数量。基于 RFC 9331 定义的 ECN 标记类型进行计数。

## 头文件接口 (.h)

### `EcnMarkingCounter` 类

**查询方法**：

| 方法 | 返回 | 说明 |
|------|------|------|
| `not_ect()` | int | 未设置 ECT 的包数 |
| `ect_0()` | int | 设置 ECT(0) 的包数（WebRTC 和 L4S 不使用） |
| `ect_1()` | int | 设置 ECT(1) 的包数（L4S 使用） |
| `ce()` | int | 标记为 CE（拥塞经历）的包数 |

**操作方法**：
- `Add(EcnMarking ecn)` — 为指定 ECN 标记类型的计数加 1。
- `operator+=` — 合并另一个计数器的所有计数值。

## 实现文件 (.cc)

- `Add()` 使用 switch 语句为对应标记类型递增计数。
- `operator+=` 分别累加四种标记类型的计数。

## 学习扩展

- **ECN 标记**: IP 头中使用 2 位表示：00=Not ECT, 01=ECT(1), 10=ECT(0), 11=CE。
- **RFC 9331**: 定义了 L4S 架构中 ECN 的使用。

## 设计模式

- **计数器模式** — 简单的累加计数器，用于统计 ECN 标记分布。
