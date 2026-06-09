# dual_pi2_network_queue

## 概述

`DualPi2NetworkQueue` 是一个简化版的 Dual PI2 AQM（Active Queue Management，主动队列管理）控制器实现，用于网络模拟测试。它实现了 RFC 9332 中描述的 Dual Queue 概念，支持 L4S（Low Latency, Low Loss, Scalable throughput）和 Classic 两种队列分别管理。

## 头文件接口 (.h)

### `DualPi2NetworkQueue` 类

继承自 `NetworkQueue`：

**`Config` 配置**：
- `target_delay` — 目标延迟（默认 500 us）
- `link_rate` — 链路速率，用于计算队列容量上限
- `alpha` / `beta` — PI 控制器的比例/积分因子
- `k` — 耦合因子（默认 2）
- `probability_update_interval` — 标记概率更新间隔（默认 16ms）
- `seed` — 随机种子

核心方法：

| 方法 | 说明 |
|------|------|
| `EnqueuePacket(packet_info)` | 入队，根据 ECN 标记分配到 L4S 或 Classic 队列 |
| `PeekNextPacket()` | 查看下一个要出队的包（优先 L4S） |
| `DequeuePacket(time_now)` | 出队，优先从 L4S 队列提取 |
| `DequeueDroppedPackets()` | 始终返回空（DualPi2 总是尾部丢弃） |
| `SetMaxPacketCapacity(capacity)` | 设置最大包容量 |

公开用于测试的方法：
- `l4s_marking_probability()` — L4S 队列的标记概率（`base * k`）
- `classic_drop_probability()` — Classic 队列的丢弃概率（`base^2`）

### `DualPi2NetworkQueueFactory` 类

实现 `NetworkQueueFactory`，创建配置好的 `DualPi2NetworkQueue` 实例。

## 实现文件 (.cc)

**入队逻辑** (`EnqueuePacket`)：
1. 检查包容量，超出则丢弃。
2. 检查 ECN 标记：
   - `kNotEct` 或 `kEct0` → Classic 流量，根据丢弃概率判断是否入队。
   - `kEct1` 或 `kCe` → L4S 流量，根据标记概率判断是否 CE 标记。

**出队逻辑** (`DequeuePacket`)：
1. 优先从 L4S 队列出队。
2. 出队时若为 ECT1，可能再次应用标记概率修改为 CE。

**`UpdateBaseMarkingProbability()`**：
1. 计算逗留时间（sojourn time）= 当前队列中 L4S 和 Classic 的最大延迟。
2. PI 控制器：`delta = alpha * (sojourn - target) + beta * (sojourn - previous_sojourn)`。
3. 将 base_marking_probability 限制在 [0, 1] 范围内。

**`ShouldTakeAction()`**：
1. 如果队列总大小超过 `step_threshold_`（2 * target_delay * link_rate），强制触发动作。
2. 否则按标记概率随机决定。

## 学习扩展

- **L4S (Low Latency, Low Loss, Scalable throughput)**: 由 RFC 9332 定义的新型拥塞控制架构，通过在网络中间节点标记 ECN（CE）来信号化早期拥塞，实现低延迟和高吞吐量。
- **Dual Queue**: L4S 流量和 Classic 流量使用不同的队列管理策略。
- **PI 控制器**: 使用比例-积分控制器计算标记/丢弃概率。
- **ECN (Explicit Congestion Notification)**: IP 层和传输层的显式拥塞通知机制。
- **AQM (Active Queue Management)**: 在队列满之前主动丢弃或标记包以信号化拥塞。

## 设计模式

- **队列模式** — 实现 `NetworkQueue` 接口的先进先出队列。
- **工厂模式** — `DualPi2NetworkQueueFactory` 创建队列实例。
- **策略模式** — Dual PI2 作为 AQM 策略的实现。
