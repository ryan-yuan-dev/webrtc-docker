# rtc_event_log

## 概述

`rtc_event_log` 定义了 RTC 事件日志系统的核心接口 `RtcEventLog`。该系统用于记录 WebRTC 通话过程中的各类事件，支持启动/停止日志记录，以及将事件输出到指定目标（如文件）。同时提供了 `RtcEventLogNull` —— 一个空操作实现，用于禁用日志或测试场景。

## 头文件接口 (.h)

### `RtcEventLog` 抽象类

| 方法 | 说明 |
|------|------|
| `StartLogging(unique_ptr<RtcEventLogOutput>, int64_t output_period_ms)` | 启动日志记录，绑定输出目标和输出周期 |
| `StopLogging()` | 停止日志并等待文件关闭 |
| `StopLogging(function<void()> callback)` | 停止日志，完成时回调通知 |
| `Log(unique_ptr<RtcEvent>)` | 记录一个事件 |

**常量：**
- `kUnlimitedOutput = 0` — 输出大小无限制
- `kImmediateOutput = 0` — 立即输出，不缓冲

**`EncodingType` 枚举：**
- `Legacy` — 旧版编码格式
- `NewFormat` — 新版格式
- `ProtoFree` — Protobuf-free 格式

### `RtcEventLogNull` 空实现类

空操作实现，所有方法直接返回或空操作：
- `StartLogging` 返回 `false`
- `StopLogging` 空操作
- `Log` 丢弃事件

## 实现文件 (.cc)

- `RtcEventLogNull::StartLogging` 返回 `false`。

## 学习扩展

- **RtcEventLogOutput**: 输出目标的抽象接口，可能的实现包括文件输出、内存输出等。
- **事件日志编码**: 事件在输出前需要编码为二进制格式，编码方式由 `EncodingType` 决定。
- **Kill Switch**: 通过 field trial `WebRTC-RtcEventLogKillSwitch` 可以远程禁用事件日志。

## 设计模式

- **抽象基类模式** — `RtcEventLog` 定义了日志记录的标准接口。
- **空对象模式** — `RtcEventLogNull` 作为空操作实现，避免在禁用日志时进行空指针检查。
- **策略模式（输出策略）** — 通过 `RtcEventLogOutput` 抽象不同的输出目标。
