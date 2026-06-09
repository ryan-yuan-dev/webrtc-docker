# leaky_bucket_network_queue

## 概述

`LeakyBucketNetworkQueue` 是一个基于漏桶（Leaky Bucket）算法的网络队列实现。它限制可排队的包数量，并在包出队时根据 ECT1 逗留时间选择性进行 CE 标记，模拟 L4S 拥塞信号行为。

## 头文件接口 (.h)

### `LeakyBucketNetworkQueue` 类

继承自 `NetworkQueue`：

**`Config` 配置**：
- `seed` — 随机种子
- `max_ect1_sojourn_time` — ECT1 包最大逗留时间（超过此时间则以 p=1 标记 CE）
- `target_ect1_sojourn_time` — ECT1 包目标逗留时间（超此时间开始标记 CE）

核心方法：

| 方法 | 说明 |
|------|------|
| `SetMaxPacketCapacity(max_capacity)` | 设置最大包容量 |
| `EnqueuePacket(packet_info)` | 入队，容量不足时拒绝 |
| `PeekNextPacket()` | 查看下一个包 |
| `DequeuePacket(time_now)` | 出队，根据逗留时间决定是否 CE 标记 |
| `DequeueDroppedPackets()` | 取出被丢弃的包 |
| `DropOldestPacket()` | 丢弃最老的包 |

### `LeakyBucketNetworkQueueFactory` 类

创建 `LeakyBucketNetworkQueue` 实例的工厂。

## 实现文件 (.cc)

**`MaybeMarkAsCe()`**:
1. 仅对 ECT1 包且在 `target_ect1_sojourn_time` 和 `max_ect1_sojourn_time` 均为有限值时执行。
2. 计算逗留时间 = 当前时间 - 包发送时间。
3. 计算标记概率 `p_mark = clamp((sojourn - target) / (max - target), 0, 1)`。
4. 按概率随机决定是否将 ECN 标记改为 CE。

**`DropOldestPacket()`**: 将最老的包移入 `dropped_packets_` 向量，供后续通过 `DequeueDroppedPackets()` 取出。

## 学习扩展

- **漏桶算法**: 一种流量整形算法，通过限制队列大小控制网络拥塞。
- **ECT1 CE 标记**: 模拟 L4S 兼容的网络节点行为，根据逗留时间概率性地标记 CE。

## 设计模式

- **队列模式** — 标准 FIFO 队列实现。
- **工厂模式** — `LeakyBucketNetworkQueueFactory` 创建队列实例。
