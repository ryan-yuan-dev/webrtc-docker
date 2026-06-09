# tick_timer

## 概述

`tick_timer` 模块实现了一个简单的滴答计数器（Tick Counter）。其基本假设是每"滴答"对应 10ms 的音频时长。`TickTimer` 提供两种关联的计时工具：`Stopwatch`（秒表，测量经过的滴答数）和 `Countdown`（倒计时，在指定滴答数后触发完成信号）。

该模块是 NetEq 延迟管理和决策逻辑的时间基准。

## 头文件接口 (.h)

### `TickTimer` 类

| 方法 | 说明 |
|------|------|
| `TickTimer()` | 默认构造，`ms_per_tick_` 为 10 |
| `explicit TickTimer(int ms_per_tick)` | 自定义每滴答毫秒数 |
| `Increment()` | 滴答数 +1 |
| `Increment(uint64_t x)` | 滴答数 +x |
| `ticks()` | 返回当前滴答数（uint64_t） |
| `ms_per_tick()` | 返回每滴答的毫秒数 |
| `GetNewStopwatch()` | 返回一个新的 Stopwatch 实例 |
| `GetNewCountdown(uint64_t)` | 返回一个新的 Countdown 实例 |

### `TickTimer::Stopwatch` 类（嵌套）

- **`ElapsedTicks()`** — 返回自 Stopwatch 创建以来的滴答数。
- **`ElapsedMs()`** — 返回自 Stopwatch 创建以来的毫秒数，处理溢出保护。
- 内部持有 `const TickTimer&` 引用和起始滴答计数值。

### `TickTimer::Countdown` 类（嵌套）

- **`Finished()`** — 返回是否已达到指定滴答数。
- 内部使用 `Stopwatch` 实例测量经过时间，与目标滴答数比较。

## 实现文件 (.cc)

### 关键实现逻辑

- `Stopwatch` 构造函数记录创建时的 `ticktimer.ticks()` 作为起始计数值。
- `ElapsedTicks()` 通过当前 `ticktimer.ticks() - starttick_` 计算。
- `ElapsedMs()` 计算 `elapsed_ticks * ms_per_tick`，并做溢出保护（`UINT64_MAX` 兜底）。
- `Countdown` 内部创建一个 `Stopwatch`，检查其 `ElapsedTicks() >= ticks_to_count_`。
- `TickTimer` 拷贝构造和拷贝赋值被删除，所有关联的 Stopwatch/Countdown 只持有引用。

### 单元测试 (`tick_timer_unittest.cc`)

| 测试 | 说明 |
|------|------|
| `DefaultMsPerTick` | 默认 `ms_per_tick` 为 10 |
| `CustomMsPerTick` | 自定义 `ms_per_tick` 功能 |
| `Increment` | 单步和多步递增功能 |
| `WrapAround` | 滴答计数值 uint64_t 溢出回绕处理 |
| `Stopwatch` | Stopwatch 从创建时刻开始计时，滴答递增后 ElapsedTicks 相应增加 |
| `StopwatchWrapAround` | 滴答计数器溢出时 Stopwatch 仍正确计时 |
| `StopwatchMsOverflow` | ElapsedMs 溢出保护行为 |
| `StopwatchWithCustomTicktime` | 自定义 ticktime 的毫秒计算 |
| `Countdown` | Countdown 在指定滴答数后完成 |
