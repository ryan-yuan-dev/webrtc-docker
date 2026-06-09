# network_emulation_interfaces

## 概述

`network_emulation_interfaces` 定义了网络模拟层的基础数据结构、统计信息结构和接口。包括 `EmulatedIpPacket`（模拟 IP 包）、`EmulatedEndpoint`（网络端点）、`TcpMessageRoute`（TCP 消息路由）等核心抽象。

## 头文件接口 (.h)

### 数据结构

**`EmulatedIpPacket`** — 模拟的 IP 包：
- `from` / `to` — 源/目的 SocketAddress
- `data` — 包数据（CopyOnWriteBuffer）
- `headers_size` — 头部开销大小
- `arrival_time` — 到达时间
- `ecn` — ECN 标记
- `ip_packet_size()` — IP 包总大小（载荷 + 头部）

**`EmulatedNetworkOutgoingStats`** — 传出统计：
- `packets_sent`, `bytes_sent` — 发送包数/字节数
- `sent_packets_size` — 发送包大小分布（Debug 模式下收集）
- `first_packet_sent_time` / `last_packet_sent_time` — 首/末包发送时间
- `ecn_count` — ECN 标记计数
- `AverageSendRate()` — 平均发送速度

**`EmulatedNetworkIncomingStats`** — 传入统计：
- `packets_received`, `bytes_received` — 接收包数/字节数
- `packets_discarded_no_receiver` — 无接收者的丢弃包
- 首/末包接收时间、平均接收速度等

**`EmulatedNetworkStats`** — 综合统计：
- 包含整体传出/传入统计
- 按目的 IP 和来源 IP 的详细统计
- `sent_packets_queue_wait_time_us` — 包排队等待时间

**`EmulatedNetworkNodeStats`** — 节点统计：
- `packet_transport_time` — 包在节点中的传输时间
- `size_to_packet_transport_time` — 包大小与传输时间比值

### 接口定义

**`EmulatedNetworkReceiverInterface`** — 接收器接口：
- `OnPacketReceived(EmulatedIpPacket)` — 收到包时调用

**`EmulatedEndpoint`** — 网络端点抽象：
- `SendPacket(from, to, data, overhead, ecn)` — 发送包
- `BindReceiver(port, receiver)` — 绑定接收器到端口
- `UnbindReceiver(port)` — 解绑接收器
- `BindDefaultReceiver(receiver)` — 绑定默认接收器
- `UnbindDefaultReceiver()` — 解绑默认接收器
- `GetPeerLocalAddress()` — 获取本地地址

**`TcpMessageRoute`** — 模拟 TCP 连接：
- `SendMessage(size, on_received)` — 发送消息，delivery 保证

## 实现文件 (.cc)

- `EmulatedIpPacket` 构造函数计算头部开销（IP 层 + UDP 层）。
- `AverageSendRate()` 和 `AverageReceiveRate()` 排除第一个包的大小，基于总字节数和时间跨度计算。

## 学习扩展

- **CopyOnWriteBuffer**: WebRTC 的写时拷贝缓冲区，用于减少数据拷贝。
- **IP Overhead**: IPv4 至少 20 字节头部，IPv6 至少 40 字节，UDP 固定 8 字节。
- **Emulated vs Real**: 所有端点都工作在模拟网络中，不涉及真实网络接口。

## 设计模式

- **接口隔离原则** — `EmulatedNetworkReceiverInterface` 作为独立的接收器接口。
- **值对象模式** — 统计数据结构（`EmulatedNetworkStats` 等）作为数据传输对象。
- **工厂方法模式** — 端点通过 `NetworkEmulationManager::CreateEndpoint` 创建。
