# neteq_simulator_factory

## 概述

`neteq_simulator_factory` 模块提供 `NetEqSimulator` 实例的创建工厂。支持从 RTP 事件日志文件或内存中的文件内容创建模拟器，使用替换音频文件作为音频源。

## 头文件接口 (.h)

### `NetEqSimulatorFactory` 类

**`Config` 配置结构体**：

| 字段 | 类型 | 说明 |
|------|------|------|
| `max_nr_packets_in_buffer` | int | 抖动缓冲最大包数 |
| `initial_dummy_packets` | int | 模拟开始前插入的占位包数 |
| `skip_get_audio_events` | int | 跳过开头的 GetAudio 事件数 |
| `field_trial_string` | string | WebRTC field trial 字符串 |
| `output_audio_filename` | optional<string> | 输出音频文件名 |
| `python_plot_filename` | optional<string> | Python 绘图脚本文件名 |
| `text_log_filename` | optional<string> | 文本日志文件名 |
| `neteq_factory` | NetEqFactory* | 自定义 NetEq 工厂 |
| `ssrc_filter` | optional<uint32_t> | SSRC 过滤 |

工厂方法：

| 方法 | 说明 |
|------|------|
| `CreateSimulatorFromFile(event_log, replacement_audio, config)` | 从事件日志文件创建模拟器 |
| `CreateSimulatorFromString(event_log_string, replacement_audio, config)` | 从事件日志字符串创建模拟器 |

## 实现文件 (.cc)

- 内部持有 `NetEqTestFactory` 实例。
- `convertConfig()` 将公用配置转换为内部 `NetEqTestFactory::Config`。
- 两种创建方法最终都委托给 `NetEqTestFactory` 的 `InitializeTestFromFile` 或 `InitializeTestFromString`。

## 学习扩展

- **RTP 事件日志**: WebRTC 通话过程中记录的 RTP 包收发事件，可用于离线分析和回放。
- **替换音频文件**: 由于 NetEq 模拟需要使用音频数据解码，但原始音频不可用，需要提供替换音频文件。

## 设计模式

- **工厂方法模式** — 创建 `NetEqSimulator` 实例。
- **适配器模式** — 将内部 `NetEqTestFactory` 适配为 `NetEqSimulatorFactory` 的公用接口。
