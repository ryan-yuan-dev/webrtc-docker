# neteq

## 概述

`neteq` 模块定义了 WebRTC NetEq 的核心接口。NetEq（Network Equalizer）是 WebRTC 音频引擎中负责抖动缓冲和丢包隐藏（PLC）的关键组件。它的职责包括：

1. **抖动缓冲** — 吸收网络抖动（jitter），将不规则的包到达变为平滑的音频输出。
2. **丢包隐藏** — 通过扩频、缩频和语音合成等技术补偿丢失的音频包。
3. **编解码器管理** — 动态注册和管理音频编解码器。
4. **NACK 支持** — 提供重传请求列表。

此头文件定义了 `NetEq` 抽象基类及其关联的数据结构。

## 头文件接口 (.h)

### `NetEq::Config` 配置结构体

| 字段 | 类型 | 默认值 | 说明 |
|------|------|--------|------|
| `sample_rate_hz` | int | 48000 | 初始采样率，随输入数据变化 |
| `max_packets_in_buffer` | size_t | 200 | 包缓冲区的最大包数 |
| `max_delay_ms` | int | 0 | 最大延迟（ms），0 表示无限制 |
| `min_delay_ms` | int | 0 | 最小延迟（ms） |
| `enable_fast_accelerate` | bool | false | 启用快速加速 |
| `enable_muted_state` | bool | false | 启用在长时间扩展后的静音状态 |
| `enable_rtx_handling` | bool | false | 启用重传包处理 |
| `codec_pair_id` | optional | nullopt | 编解码器对 ID，用于关联编解码器 |
| `for_test_no_time_stretching` | bool | false | 仅测试用，禁用时间伸缩 |

### 数据结构

**`NetEqNetworkStatistics`** — 网络统计信息（可重置）：
- `current_buffer_size_ms` / `preferred_buffer_size_ms` — 当前/目标抖动缓冲大小
- `jitter_peaks_found` — 是否检测到抖动尖峰
- `expand_rate` / `speech_expand_rate` — 扩展（丢包隐藏）比例（Q14 格式）
- `preemptive_rate` / `accelerate_rate` — 预扩/加速比例（Q14 格式）
- `secondary_decoded_rate` / `secondary_discarded_rate` — FEC/RED 解码/丢弃比例
- 等待时间统计（均值/中位数/最小值/最大值）

**`NetEqLifetimeStatistics`** — 生命周期统计（不重置）：
- `concealed_samples` / `concealment_events` — 隐藏样本数和事件数
- `jitter_buffer_delay_ms` / `jitter_buffer_emitted_count` — 抖动缓冲延迟
- `fec_packets_received` / `fec_packets_discarded` — FEC 包接收/丢弃
- `interruption_count` / `total_interruption_duration_ms` — 中断统计（>=150ms 的丢失隐藏事件）
- `total_processing_delay_us` — 总处理延迟

**`NetEqOperationsAndState`** — 操作与内部状态统计：
- `preemptive_samples` / `accelerate_samples` — 预扩/加速样本数
- `packet_buffer_flushes` — 缓冲区刷新次数
- `last_waiting_time_ms` / `current_buffer_size_ms` / `current_frame_size_ms` — 当前状态
- `next_packet_available` — 是否有下一个包可用

**`DecoderFormat`** — 解码器格式信息：
- `payload_type` / `sample_rate_hz` / `num_channels` / `sdp_format`

### `NetEq` 纯虚接口

| 方法 | 说明 |
|------|------|
| `InsertPacket()` | 插入 RTP 音频包，三个重载版本（向后兼容） |
| `InsertEmptyPacket()` | 插入空包（用于网络探测） |
| `GetAudio()` | 获取 10ms 音频数据，支持静音状态和动作覆盖 |
| `SetCodecs()` | 批量替换解码器 |
| `RegisterPayloadType()` | 注册 RTP payload type 编解码器映射 |
| `CreateDecoder()` | 预创建解码器（减少首次延迟） |
| `RemovePayloadType()` / `RemoveAllPayloadTypes()` | 移除/清空解码器注册 |
| `SetMinimumDelay()` / `SetMaximumDelay()` | 最小/最大延迟控制 |
| `SetBaseMinimumDelayMs()` / `GetBaseMinimumDelayMs()` | 基准最小延迟（比 SetMinimumDelay 更低的硬边界） |
| `TargetDelayMs()` | 当前目标延迟 |
| `FilteredCurrentDelayMs()` | 平滑后的当前总延迟 |
| `NetworkStatistics()` | 获取并重置网络统计 |
| `CurrentNetworkStatistics()` | 获取当前统计（不重置） |
| `GetLifetimeStatistics()` | 获取生命周期统计 |
| `GetOperationsAndState()` | 获取操作与状态统计 |
| `GetPlayoutTimestamp()` | 获取最后送出的音频 RTP 时间戳 |
| `last_output_sample_rate_hz()` | 上次输出采样率 |
| `GetDecoderFormat()` / `GetCurrentDecoderFormat()` | 获取解码器格式（后者标记为推荐） |
| `FlushBuffers()` | 刷新所有缓冲区 |
| `EnableNack()` / `DisableNack()` | NACK 开关控制 |
| `GetNackList()` | 获取需重传的 RTP 序列号列表 |
| `SyncBufferSizeMs()` | 同步缓冲区的待播放音频长度 |

### 枚举类型

- **`ReturnCodes`**: `kOK = 0`, `kFail = -1`
- **`Operation`**: 定义了 10 种操作类型，包括 `kNormal`（正常）、`kMerge`（合并）、`kExpand`（扩展）、`kAccelerate`（加速）、`kPreemptiveExpand`（预扩）、`kRfc3389Cng`（舒适噪声）、`kDtmf`（DTMF 音）等。
- **`Mode`**: 定义了 15 种模式状态，在 `kAccelerate` 和 `kPreemptiveExpand` 下进一步细分成功/低能量/失败子状态。

## 实现文件 (.cc)

- `Config` 的构造/拷贝/赋值/析构函数均使用 `= default`。
- `ToString()` 使用 `SimpleStringBuilder` 将关键配置格式化为可读字符串。

## 学习扩展

- **Q14 格式**: WebRTC 用 Q14（14 位小数位）定点数表示分数比例，值范围为 [0, 16384)，对应浮点 [0, 1)。除以 16384 得到真实比例。
- **丢包隐藏(PLC)**: NetEq 对丢失音频包采取三种策略 — 扩展（重复/拉伸前一个包）、融合（拼接新旧包）、加速（压缩静音）。
- **抖动缓冲机制**: 包缓冲 + 同步缓冲两级架构，前者吸收乱序和抖动，后者处理时间伸缩。
- **RFC 3389**: 舒适噪声（CNG）标准。
- **FEC/RED**: 前向纠错和冗余编码，NetEq 跟踪其解码和丢弃比例。

## 设计模式

- **抽象基类模式** — `NetEq` 作为纯虚接口类，定义了完整的抖动缓冲功能契约。
- **工厂方法模式** — 通过 `NetEqFactory` 和 `NetEqControllerFactory` 创建具体实现。
- **值对象模式** — 统计数据结构（`NetEqNetworkStatistics`、`NetEqLifetimeStatistics` 等）作为数据传输对象（DTO）。
- **策略模式** — 通过 `Operation` 枚举选择不同的音频处理策略。
