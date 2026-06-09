# voip_engine_factory

## 概述

`voip_engine_factory` 模块提供了创建 `VoipEngine` 实例的工厂方法。`VoipEngine` 是 WebRTC VoIP（Voice over IP）引擎的接口，此模块定义了创建引擎所需的配置结构体 `VoipEngineConfig` 和工厂函数 `CreateVoipEngine`。

## 头文件接口 (.h)

### `VoipEngineConfig` 配置结构体

| 字段 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `encoder_factory` | scoped_refptr<AudioEncoderFactory> | 是 | 音频编码器工厂，提供编码用的音频编解码器 |
| `decoder_factory` | scoped_refptr<AudioDecoderFactory> | 是 | 音频解码器工厂，提供解码用的音频编解码器 |
| `task_queue_factory` | unique_ptr<TaskQueueFactory> | 否 | 异步任务队列工厂，与 `env` 互斥 |
| `audio_device_module` | scoped_refptr<AudioDeviceModule> | 是 | 音频设备模块，管理麦克风输入和扬声器输出 |
| `env` | optional<Environment> | 否 | 环境配置，与 `task_queue_factory` 互斥 |
| `audio_processing_builder` | unique_ptr<AudioProcessingBuilderInterface> | 否 | 音频处理构建器（AEC、降噪、增益控制等） |

**约束**：
- `encoder_factory`、`decoder_factory`、`audio_device_module` 为强制要求。
- `task_queue_factory` 和 `env` 是互斥的，不能同时设置两者。
- 若 `env` 未设置，使用 `CreateEnvironment(task_queue_factory)` 创建默认环境。

### `CreateVoipEngine()` 工厂函数

- 签名：`std::unique_ptr<VoipEngine> CreateVoipEngine(VoipEngineConfig config)`
- 返回 VoipEngine 的唯一所有权。

## 实现文件 (.cc)

### 关键实现逻辑

1. **必填参数检查**: 使用 `RTC_CHECK` 断言 `encoder_factory`、`decoder_factory`、`audio_device_module` 非空。
2. **互斥检查**: 断言 `task_queue_factory == nullptr || !config.env.has_value()`。
3. **Environment 创建**: 如果提供了 `env` 则使用，否则使用 `CreateEnvironment(std::move(config.task_queue_factory))`。
4. **音频处理构建**: 如果提供了 `audio_processing_builder`，调用其 `Build(env)` 创建 `AudioProcessing` 实例；否则为 nullptr。
5. **VoipCore 构建**: 创建 `VoipCore` 实例（位于 `audio/voip/` 内部模块）。

### 单元测试 (`voip_engine_factory_unittest.cc`)

| 测试 | 说明 |
|------|------|
| `CreateEngineWithMockModules` | 使用 mock 模块正常创建 VoipEngine，包含音频处理 |
| `UseNoAudioProcessing` | 不设置音频处理配置，引擎也能正常创建 |

## 学习扩展

- **VoIP 引擎架构**: WebRTC 的 VoIP 引擎是简化版的音频通话功能集，相比完整的 PeerConnection API，VoIP 引擎提供了更轻量级的音频通话能力。
- **VoipEngine 接口层**: `VoipEngine` 接口分为多个子接口（`VoipBase`、`VoipNetwork`、`VoipCodec`、`VoipDtmf`、`VoipStatistics`、`VoipVolumeControl`），分别管理通话的不同方面。
- **AudioProcessing**: 提供 AEC（声学回声消除）、NS（降噪）、AGC（自动增益控制）等音频预处理功能。

## 设计模式

- **工厂方法模式** — `CreateVoipEngine` 封装了 `VoipEngine` 实例的创建逻辑。
- **参数对象模式** — `VoipEngineConfig` 将所有配置参数封装为一个对象，避免工厂方法参数过多。
- **依赖注入** — 编解码器工厂、音频设备模块等依赖通过参数注入，而非硬编码。
