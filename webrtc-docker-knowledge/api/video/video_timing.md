# video_timing

## 概述

`video_timing.h` 定义了 WebRTC 视频时序相关的三个主要结构体/类：`VideoSendTiming`（发送端时序，作为 RTP 头部扩展传输）、`TimingFrameInfo`（完整帧时序报告，用于统计和诊断）和 `VideoPlayoutDelay`（播放延迟约束）。这些组件共同构成了视频帧从采集到渲染全生命周期的时序追踪体系。

## 头文件接口 (.h)

- **`VideoSendTiming`**：
  - `TimingFrameFlags`：标记帧追踪触发原因——`kNotTriggered`、`kTriggeredByTimer`、`kTriggeredBySize`、`kInvalid`。
  - 16 位增量字段：`encode_start_delta_ms`、`encode_finish_delta_ms`、`packetization_finish_delta_ms`、`pacer_exit_delta_ms`、`network_timestamp_delta_ms`、`network2_timestamp_delta_ms`，均相对于采集时间。
  - `GetDeltaCappedMs()`：静态工具方法，计算时间差并截断为 uint16_t。
  - `flags`：8 位标志位。
- **`TimingFrameInfo`**：
  - 全部时序字段：从 `rtp_timestamp`、`capture_time_ms` 到 `decode_start_ms`、`decode_finish_ms`、`render_time_ms`，共 14 个时间戳。
  - `EndToEndDelay()`：端到端延迟（decode_finish - capture_time）。
  - `IsLongerThan()`：比较两个帧的总处理时间。
  - `IsOutlier()` / `IsTimerTriggered()` / `IsInvalid()`：标志位辅助查询。
  - `operator<` / `operator<=`：基于端到端延迟的比较。
  - `ToString()`：序列化为 CSV 格式字符串。
- **`VideoPlayoutDelay`**：
  - `kMax`：最大支持延迟 10 秒（`0xFFF * 10ms`）。
  - `Minimal()`：创建"尽快渲染"的延迟限制。
  - 构造函数接受 `min` 和 `max` 两个 `TimeDelta` 参数，自动钳制到合法范围。
  - `Set()` 方法设置延迟范围。
  - 不变式：`0 <= min <= max <= kMax`。

## 实现文件 (.cc)

- **`VideoSendTiming::GetDeltaCappedMs()`**：计算 `time_ms - base_ms` 后使用 `saturated_cast<uint16_t>()` 截断。
- **`TimingFrameInfo`**：
  - `EndToEndDelay()`：如果 `capture_time_ms >= 0` 返回 `decode_finish_ms - capture_time_ms`，否则返回 -1。
  - `IsLongerThan()`：如果对方无法计算延迟（返回 -1）或自身延迟更大则返回 true。
  - `IsOutlier()`：标志位包含 `kTriggeredBySize` 且不无效。
  - `ToString()`：以 CSV 格式输出所有时序字段。
- **`VideoPlayoutDelay`**：
  - 构造函数使用 `std::clamp` 确保 min/max 在合法范围内，若输入非法则记录日志。
  - `Set()` 仅在输入完全合法时更新，返回 true，否则不修改并返回 false。

## 学习扩展

- **RTP 视频时序扩展**：`VideoSendTiming` 的数据格式遵循 `https://webrtc.org/experiments/rtp-hdrext/video-timing/` 规范，使用 16 位增量相对于采集时间存储。
- **Timing frame 的选择策略**：周期性定时器触发（`kTriggeredByTimer`）和/或帧大小超出阈值（`kTriggeredBySize`）时标记为"timing frame"，接收端采样这些帧的时序数据用于质量统计。
- **PlayoutDelay 的端到端意义**：发送端通过 RTP 头部扩展告知接收端期望的播放延迟范围，接收端在此范围内自适应调整以平衡延迟和抖动。

## 设计模式

**值对象模式（Value Object）**：`VideoSendTiming`、`TimingFrameInfo`、`VideoPlayoutDelay` 均为值类型，提供构造函数、比较和序列化能力。`VideoPlayoutDelay` 通过构造函数和 `Set()` 方法维护不变式，体现了**防御性编程（Defensive Programming）**风格——即使输入非法也能保证对象处于有效状态。
