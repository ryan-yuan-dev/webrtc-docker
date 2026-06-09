# neteq_simulator

## 概述

`neteq_simulator` 定义了 NetEq 模拟器的接口 `NetEqSimulator`，用于在测试环境中模拟 NetEq（抖动缓冲和丢包隐藏）的行为。该模拟器可以从事件日志文件驱动 NetEq 实例，逐步骤执行并记录状态。

## 头文件接口 (.h)

### `NetEqSimulator` 抽象类

**`Action` 枚举**：
- `kNormal` — 正常操作
- `kExpand` — 扩展（丢包隐藏）
- `kAccelerate` — 加速
- `kPreemptiveExpand` — 预扩

**`SimulationStepResult` 结构体**：
- `is_simulation_finished` — 模拟是否完成
- `action_times_ms` — 本步骤中各操作的持续时长（毫秒）
- `simulation_step_ms` — 本步骤经过的墙上时钟时间

**`NetEqState` 结构体**：
- `current_delay_ms` — 当前总延迟（包缓冲 + 同步缓冲）
- `packet_loss_occurred` — 自上次 GetAudio 以来是否发生丢包
- `packet_buffer_flushed` — 缓冲区是否被刷新
- `next_packet_available` — 是否需要的数据包可用
- `packet_iat_ms` — 自上次 GetAudio 以来的包间到达时间
- `packet_size_ms` — 当前包大小

核心方法：

| 方法 | 说明 |
|------|------|
| `Run()` | 运行模拟至结束，返回生成的音频时长 |
| `RunToNextGetAudio()` | 运行到下一个 GetAudio 事件 |
| `SetNextAction(Action)` | 覆盖 NetEq 的下一个操作决策 |
| `GetNetEqState()` | 获取当前 NetEq 内部状态 |
| `GetNetEq()` | 获取底层 NetEq 实例 |

## 实现文件 (.cc)

- `SimulationStepResult` 和 `NetEqState` 的构造/拷贝/析构均为 `= default`。

## 学习扩展

- **NetEq 模拟**: 基于真实 RTP 事件日志回放 NetEq 行为，用于离线分析和测试。
- **GetAudio 事件驱动**: NetEq 每次输出 10ms 音频为一个事件，模拟器在这些事件之间插入数据包到达事件。

## 设计模式

- **模拟器模式** — 将 NetEq 的真实执行封装为可逐步调试的模拟器。
- **状态快照模式** — `GetNetEqState()` 返回当前状态的快照。
