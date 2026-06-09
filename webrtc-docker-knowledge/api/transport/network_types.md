# network_types

## 概述

`network_types.h` / `network_types.cc` 定义了 WebRTC 传输层网络控制所使用的核心数据结构。这些结构体覆盖了从码率约束、拥塞控制配置、数据包反馈、网络估计到控制更新的完整数据流。是拥塞控制子系统（GoogCC）与传输层之间交换信息的"数据契约"。

该模块定义了约 20 个结构体，分布在以下几个逻辑分组中：
- **配置类**: 码率限制、流配置、目标速率约束
- **发送端信息**: 网络可用性、路由变化、已发送包和已接收包
- **传输层反馈**: 远程码率报告、RTT 更新、丢包报告
- **数据包级反馈**: 单包结果、传输层反馈
- **网络估计**: 网络状态估计（实验性）
- **网络控制**: Pacer 配置、探测配置、目标传输速率、控制更新

## 头文件接口 (.h)

**文件**: `api/transport/network_types.h`

### 码率分配限制

```cpp
struct BitrateAllocationLimits {
  DataRate min_allocatable_rate;  // 所有发送流的最小发码率
  DataRate max_allocatable_rate;  // 所有可用流的最大可分配码率
  DataRate max_padding_rate;      // padding 包的最大码率
};
```

### 流配置

```cpp
struct StreamsConfig {
  Timestamp at_time;
  std::optional<bool> requests_alr_probing;  // ALR (应用受限区域) 探测请求
  std::optional<bool> enable_repeated_initial_probing;  // 初始阶段重复探测
  std::optional<double> pacing_factor;
  std::optional<DataRate> min_total_allocated_bitrate;
  std::optional<DataRate> max_padding_rate;
  std::optional<DataRate> max_total_allocated_bitrate;
};
```

### 目标速率约束

```cpp
struct TargetRateConstraints {
  Timestamp at_time;
  std::optional<DataRate> min_data_rate;    // 最小码率约束
  std::optional<DataRate> max_data_rate;    // 最大码率约束
  std::optional<DataRate> starting_rate;    // 起始带宽估计
};
```

- `starting_rate` 用于 `OnTargetTransferRate` 和 `OnPacerConfig` 回调的基础估计

### 发送端信息

```cpp
struct NetworkAvailability {
  Timestamp at_time;
  bool network_available;  // 网络是否可用
};

struct NetworkRouteChange {
  Timestamp at_time;
  TargetRateConstraints constraints;  // 路由变更时同步更新码率约束
};
```

### 已发送包和已接收包

```cpp
struct SentPacket {
  Timestamp send_time;
  DataSize size;               // 包含 IP 层头部开销的包大小
  DataSize prior_unacked_data; // 在途但无反馈的先前数据量
  PacedPacketInfo pacing_info;  // 探测集群信息
  bool audio;                  // 音频包标识
  int64_t sequence_number;     // 传输层独立序列号（全局唯一、单调递增）
  DataSize data_in_flight;     // 发送时的在途数据量
};

struct ReceivedPacket {
  Timestamp send_time;
  Timestamp receive_time;
  DataSize size;
};
```

### 传输层反馈

```cpp
struct RemoteBitrateReport {
  Timestamp receive_time;
  DataRate bandwidth;
};

struct RoundTripTimeUpdate {
  Timestamp receive_time;
  TimeDelta round_trip_time;
  bool smoothed;
};

struct TransportLossReport {
  Timestamp receive_time;
  Timestamp start_time;
  Timestamp end_time;
  uint64_t packets_lost_delta;
  uint64_t packets_received_delta;
};
```

### 数据包级反馈

```cpp
struct PacketResult {
  class ReceiveTimeOrder;  // 按接收时间排序的比较器

  struct RtpPacketInfo {
    uint32_t ssrc;
    uint16_t rtp_sequence_number;
    bool is_retransmission;
  };

  SentPacket sent_packet;
  Timestamp receive_time;         // PlusInfinity = 未收到（丢包）
  EcnMarking ecn;                 // 显式拥塞通知标记
  std::optional<RtpPacketInfo> rtp_packet_info;

  bool IsReceived() const;
};
```

```cpp
struct TransportPacketsFeedback {
  Timestamp feedback_time;
  DataSize data_in_flight;
  bool transport_supports_ecn;
  std::vector<PacketResult> packet_feedbacks;  // 所有包的反馈
  TimeDelta smoothed_rtt;  // 按 RFC 6298 EWMA 计算的平滑 RTT

  std::vector<Timestamp> sendless_arrival_times;

  std::vector<PacketResult> ReceivedWithSendInfo() const;
  std::vector<PacketResult> LostWithSendInfo() const;
  std::vector<PacketResult> PacketsWithFeedback() const;
  std::vector<PacketResult> SortedByReceiveTime() const;
};
```

### 网络控制

```cpp
struct PacerConfig {
  DataSize data_window;   // 时间窗口内的发送数据上限
  TimeDelta time_window;  // 时间窗口
  DataSize pad_window;    // padding 最低发送量
  DataRate data_rate() const;  // data_window / time_window
  DataRate pad_rate() const;   // pad_window / time_window
};

struct ProbeClusterConfig {
  DataRate target_data_rate;    // 探测目标码率
  TimeDelta target_duration;    // 探测持续时间
  TimeDelta min_probe_delta;    // 探测突发包之间的最小间隔（默认 2ms）
  int32_t target_probe_count;   // 目标探测包数量
  int32_t id;
};

struct TargetTransferRate {
  NetworkEstimate network_estimate;  // 估计依据
  DataRate target_rate;              // 目标码率
  double cwnd_reduce_ratio;          // 拥塞窗口缩减比例
};

struct NetworkControlUpdate {
  std::optional<DataSize> congestion_window;       // 拥塞窗口
  std::optional<PacerConfig> pacer_config;         // Pacer 配置
  std::vector<ProbeClusterConfig> probe_cluster_configs;  // 探测集群
  std::optional<TargetTransferRate> target_rate;   // 目标传输速率

  bool has_updates() const;  // 是否有更新
};
```

### 实验性网络状态估计

```cpp
struct NetworkStateEstimate {
  double confidence;                     // 置信度
  Timestamp update_time;                 // 估计更新时间
  Timestamp last_receive_time;
  Timestamp last_send_time;
  DataRate link_capacity;                // 总链路容量估计
  DataRate link_capacity_lower;          // 可用容量下限（安全值）
  DataRate link_capacity_upper;          // 容量上限（增速限制）
  TimeDelta pre_link_buffer_delay;       // 链路前缓冲延迟
  TimeDelta post_link_buffer_delay;      // 链路后缓冲延迟
  TimeDelta propagation_delay;           // 传播延迟
  // ... 调试用字段
};
```

## 实现文件 (.cc)

**文件**: `api/transport/network_types.cc`

### 默认构造/析构/拷贝

除 `PacedPacketInfo` 外，各主要结构体的构造函数均为 `= default`，没有特殊初始化逻辑：

```cpp
StreamsConfig::StreamsConfig() = default;
TargetRateConstraints::TargetRateConstraints() = default;
NetworkRouteChange::NetworkRouteChange() = default;
PacketResult::PacketResult() = default;
TransportPacketsFeedback::TransportPacketsFeedback() = default;
NetworkControlUpdate::NetworkControlUpdate() = default;
PacedPacketInfo::PacedPacketInfo() = default;
```

### PacketResult::ReceiveTimeOrder

```cpp
bool PacketResult::ReceiveTimeOrder::operator()(const PacketResult& lhs,
                                                const PacketResult& rhs) {
  if (lhs.receive_time != rhs.receive_time)
    return lhs.receive_time < rhs.receive_time;
  if (lhs.sent_packet.send_time != rhs.sent_packet.send_time)
    return lhs.sent_packet.send_time < rhs.sent_packet.send_time;
  return lhs.sent_packet.sequence_number < rhs.sent_packet.sequence_number;
}
```

- 主排序键：接收时间 (receive_time)
- 次排序键：发送时间 (send_time)
- 最终排序键：序列号 (sequence_number)

### TransportPacketsFeedback 筛选方法

```cpp
// 返回已收到的包
std::vector<PacketResult> TransportPacketsFeedback::ReceivedWithSendInfo() const;

// 返回丢失的包
std::vector<PacketResult> TransportPacketsFeedback::LostWithSendInfo() const;

// 返回所有包（直接返回 packet_feedbacks）
std::vector<PacketResult> TransportPacketsFeedback::PacketsWithFeedback() const;

// 按接收时间排序后返回已收到的包
std::vector<PacketResult> TransportPacketsFeedback::SortedByReceiveTime() const;
```

## 学习扩展

### 数据流：从网络反馈到码率决策

```
RTCP Transport Feedback 到达
       │
       ▼
TransportPacketsFeedback 构建
  ├── packet_feedbacks[]   ← 每个包的发送/到达时间
  ├── data_in_flight       ← 在途数据量
  └── smoothed_rtt         ← 平滑 RTT
       │
       ▼
GoogCcNetworkController::OnTransportPacketsFeedback()
  ├── 延迟梯度估计 (Trendline)
  ├── 丢包率统计
  └── 码率更新
       │
       ▼
NetworkControlUpdate 输出
  ├── target_rate          ← 新目标码率
  ├── pacer_config         ← Pacer 速率
  └── congestion_window    ← 拥塞窗口
```

### ECN (Explicit Congestion Notification)

`PacketResult::ecn` 字段记录显式拥塞通知标记。ECN 是网络层（IP）的拥塞信号机制，路由器在检测到拥塞时标记 ECT 包而非丢包，使发送端可以更早地检测到拥塞。

### Smoothed RTT 计算

`TransportPacketsFeedback::smoothed_rtt` 基于 RFC 6298 的指数加权移动平均 (EWMA) 计算，alpha = 1/8：

```
SRTT = (1 - alpha) * SRTT + alpha * R'
```

## 设计模式

| 模式 | 出现位置 | 说明 |
|------|----------|------|
| **Data Transfer Object (DTO)** | 所有 struct | 在系统组件之间传递数据的纯数据结构 |
| **Compositor** | `TransportPacketsFeedback` 包含 `PacketResult` 向量 | 聚合多个子结果 |
| **Builder / Fluent** | `PacketResult::IsReceived()` 等查询方法 | 对数据进行筛选和映射 |
