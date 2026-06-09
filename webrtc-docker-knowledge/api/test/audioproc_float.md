# audioproc_float

## 概述

`audioproc_float` 模块提供了一个音频处理模拟工具函数 `AudioprocFloat`。该工具可以使用录制文件（AEC dump 或 wav 文件）作为输入，模拟 AudioProcessing 模块的执行过程，并生成 wav 格式的输出文件。主要用于音频处理管线（包含回声消除、降噪、增益控制等）的效果验证和调试。

## 头文件接口 (.h)

### `AudioprocFloat()` 函数

三个重载版本，差异在于创建 AudioProcessing 实例时所使用的构建器：

| 重载 | 说明 |
|------|------|
| `AudioprocFloat(int argc, char* argv[])` | 使用默认的 `BuiltinAudioProcessingBuilder` |
| `AudioprocFloat(BuiltinAudioProcessingBuilder, argc, argv)` | 使用自定义的 BuiltinAudioProcessingBuilder（支持注入组件） |
| `AudioprocFloat(AudioProcessingBuilderInterface, argc, argv)` | 使用通用的 AudioProcessingBuilderInterface（失去 Builtin 特定功能） |

所有版本返回 int 类型的退出码。

## 实现文件 (.cc)

- 三个重载都委托给 `modules/audio_processing/test/` 内部的 `AudioprocFloatImpl`。
- 默认版本创建一个 `BuiltinAudioProcessingBuilder` 实例。
- 使用 `--helpfull` 命令行参数可以查看所有支持的标志。

## 学习扩展

- **AEC Dump**: WebRTC 支持将音频处理过程中的输入/输出录制为 AEC dump 文件（通常为 protobuf 格式），用于离线分析和调试。
- **AudioProcessing 模块**: 包含 AEC（声学回声消除）、NS（降噪）、AGC（自动增益控制）、VAD（语音活动检测）等子模块。
- **命令行工具**: `audioproc_float` 通常编译为独立的可执行文件，用于音频质量问题排查。

## 设计模式

- **外观模式** — 将复杂的 AudioProcessing 模拟过程封装为简单的函数调用。
- **委托模式** — 各重载委托给内部 `AudioprocFloatImpl` 实现。
