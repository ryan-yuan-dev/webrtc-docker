# transport

## 概述

`transport` 模块定义了 WebRTC 中 RTP/RTCP 包传输的基类接口 `Transport` 和包选项结构体 `PacketOptions`。`Transport` 是 WebRTC 的网口抽象，所有媒体和信令包的发送都通过这个接口完成。

## 头文件接口 (.h)

### `Transport` 抽象类

| 方法 | 说明 |
|------|------|
| `SendRtp(ArrayView<const uint8_t> packet, const PacketOptions&)` | 发送 RTP 包，返回是否成功 |
| `SendRtcp(ArrayView<const uint8_t> packet, const PacketOptions&)` | 发送 RTCP 包，返回是否成功 |
| `~Transport()` | 受保护虚析构函数，禁止通过基类指针删除 |

### `PacketOptions` 结构体

| 字段 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `packet_id` | int64_t | -1 | 包标识，负数表示无效 |
| `is_media` | bool | false | 是否为媒体包（音/视频），不含重传 |
| `included_in_feedback` | bool | false | 是否纳入反馈计算 |
| `included_in_allocation` | bool | false | 是否纳入带宽分配 |
| `send_as_ect1` | bool | false | ECT(1) 标记（ECN 相关） |
| `batchable` | bool | false | 是否可批量发送 |
| `last_packet_in_batch` | bool | false | 是否为批次的最后一个包 |

## 实现文件 (.cc)

- `PacketOptions` 的构造函数和析构函数都使用 `= default`。

## 学习扩展

- **Transport 与网络分离**: `Transport` 是 WebRTC 中将媒体生成与网络传输解耦的关键接口。网络层只需实现 `SendRtp` / `SendRtcp` 即可接入 WebRTC。
- **PacketOptions 的扩展**: 从简单的 `packet_id` 和 `is_media` 发展到 `batchable` / `last_packet_in_batch` 等高级特性，反映了 WebRTC 对批量发送和 ECN 的支持演进。
- **ECN (Explicit Congestion Notification)**: `send_as_ect1` 字段用于设置 IP 层的 ECN 标记，帮助网络中间节点明确信号拥塞。
- **ArrayView**: WebRTC 的非拥有视图类，类似于 `std::string_view` 但用于任意类型数组。

## 设计模式

- **策略模式** — `Transport` 作为网络发送策略的抽象接口，不同的网络实现（如直接 UDP 发送、通过 ICE 发送、测试模拟发送）都实现此接口。
- **桥接模式** — 将媒体生成（WebRTC 内部）与网络传输（外部实现）解耦。
