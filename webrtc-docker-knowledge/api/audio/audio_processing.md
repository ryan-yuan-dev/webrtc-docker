# audio_processing

## 概述

`audio_processing` 定义了 WebRTC 音频处理模块（Audio Processing Module, APM）的核心接口 `AudioProcessing`，是整个 WebRTC 音频处理管线的中枢。APM 提供回声消除（AEC）、噪声抑制（NS）、自动增益控制（AGC）、高通滤波（HPF）等语音处理组件，专为实时通信场景设计。

APM 以逐帧方式处理两条音频流：
- **主流（Primary Stream / Capture）**：近端采集音频，通过 `ProcessStream()` 传入，应用全部处理效果。
- **反向流（Reverse Stream / Render）**：远端渲染音频，通过 `ProcessReverseStream()` 传入，用于回声参考。

该文件同时定义了核心辅助接口：`StreamConfig`、`ProcessingConfig`、`RuntimeSetting`、`EchoDetector`、`CustomAudioAnalyzer`、`CustomProcessing`，以及 `AudioProcessingBuilderInterface` 工厂接口。

## 头文件接口 (.h)

### 类 AudioProcessing（核心接口）

AudioProcessing 继承 `RefCountInterface`（引用计数生命周期管理），标记为 `RTC_EXPORT`。

| 方法 | 说明 |
|------|------|
| `Initialize()` | 初始化内部状态，保留用户设置 |
| `Initialize(ProcessingConfig)` | 带处理配置的初始化 |
| `ApplyConfig(Config)` | 应用配置参数 |
| `ProcessStream(int16/float)` | 处理采集帧（主方向） |
| `ProcessReverseStream(int16/float)` | 处理渲染帧（反向方向） |
| `AnalyzeReverseStream(float)` | 仅分析渲染信号（无输出） |
| `GetLinearAecOutput()` | 获取最近 10ms 的线性 AEC 输出（16kHz mono） |
| `set_stream_analog_level()` | 设置当前模拟增益等级（0-255） |
| `recommended_stream_analog_level()` | 获取推荐的模拟增益等级 |
| `set_stream_delay_ms()` | 设置回声路径延迟（ms） |
| `set_stream_key_pressed()` | 标记按键事件 |
| `CreateAndAttachAecDump()` | 创建并附加 AEC 调试日志 |
| `AttachAecDump()` / `DetachAecDump()` | 附加/分离 AEC 调试日志 |
| `GetStatistics()` | 获取音频处理统计信息 |
| `GetConfig()` | 获取当前配置 |
| `SetRuntimeSetting()` / `PostRuntimeSetting()` | 设置运行时参数（非配置阶段调整） |

### 配置结构 AudioProcessing::Config

Config 是 APM 的参数集合，通过嵌套结构组织各子模块配置：

| 子配置 | 说明 |
|--------|------|
| `pipeline` | 处理管线属性（最大内部处理速率、多声道处理开关、capture downmix 方式） |
| `pre_amplifier` | 前置放大器（处理前放大信号） |
| `capture_level_adjustment` | 采集信号增益调整（pre/post gain，模拟麦克风增益模拟） |
| `high_pass_filter` | 高通滤波器 |
| `echo_canceller` | 回声消除（标准模式/移动模式，线性 AEC 输出导出） |
| `noise_suppression` | 噪声抑制（低/中/高/极高 四个等级） |
| `transient_suppression` | 瞬态抑制（已废弃） |
| `gain_controller1` | AGC1（传统自动增益控制，模拟/自适应数字/固定数字三种模式） |
| `gain_controller2` | AGC2（新一代 AGC，包含输入音量控制器、自适应数字控制器、固定增益和限幅器） |

**Config 详细字段：**

**Pipeline**
| 字段 | 默认值 | 说明 |
|------|--------|------|
| `maximum_internal_processing_rate` | 48000 | 最大内部处理速率，仅支持 32000/48000 |
| `multi_channel_render` | false | 多声道渲染处理 |
| `multi_channel_capture` | false | 多声道采集处理（AEC3 激活时） |
| `capture_downmix_method` | kAverageChannels | 多声道 downmix 方式 |

**PreAmplifier / CaptureLevelAdjustment**
| 字段 | 默认值 | 说明 |
|------|--------|------|
| `pre_amplifier.enabled` | false | 前置放大使能 |
| `pre_amplifier.fixed_gain_factor` | 1.0f | 固定增益因子 |
| `capture_level_adjustment.pre_gain_factor` | 1.0f | 处理前增益 |
| `capture_level_adjustment.post_gain_factor` | 1.0f | 处理后增益 |

**EchoCanceller**
| 字段 | 默认值 | 说明 |
|------|--------|------|
| `enabled` | false | 回声消除使能 |
| `mobile_mode` | false | 移动模式（低复杂度） |
| `export_linear_aec_output` | false | 导出线性 AEC 输出 |
| `enforce_high_pass_filtering` | true | 强制高通滤波 |

**NoiseSuppression**
| 字段 | 默认值 | 说明 |
|------|--------|------|
| `enabled` | false | 噪声抑制使能 |
| `level` | kModerate | 抑制强度（Low/Moderate/High/VeryHigh） |

**GainController1**（传统 AGC）
| 字段 | 默认值 | 说明 |
|------|--------|------|
| `enabled` | false | AGC1 使能 |
| `mode` | kAdaptiveAnalog | 模式（AdaptiveAnalog/AdaptiveDigital/FixedDigital） |
| `target_level_dbfs` | 3 | 目标电平（-3 dBFs） |
| `compression_gain_db` | 9 | 压缩增益（dB），0-90 |
| `enable_limiter` | true | 限幅器使能 |

**GainController2**（新一代 AGC）
| 字段 | 默认值 | 说明 |
|------|--------|------|
| `enabled` | false | AGC2 使能 |
| `adaptive_digital.headroom_db` | 5.0 | 自适应数字控制的 headroom |
| `adaptive_digital.max_gain_db` | 50.0 | 最大增益 |
| `adaptive_digital.max_gain_change_db_per_second` | 6.0 | 最大增益变化速率 |
| `fixed_digital.gain_db` | 0.0 | 固定数字增益 |

### 类 AudioProcessing::RuntimeSetting

运行时设置，用于在 APM 运行期间动态调整参数而不触发子模块复位。

| 创建方法 | 说明 |
|----------|------|
| `CreateCapturePreGain(gain)` | 设置采集前增益（float） |
| `CreateCapturePostGain(gain)` | 设置采集后增益（float） |
| `CreateCompressionGainDb(gain_db)` | 设置压缩增益（int, 0-90） |
| `CreateCaptureFixedPostGain(gain_db)` | 设置 AGC2 固定后增益（float, 0-90） |
| `CreatePlayoutAudioDeviceChange(info)` | 通知播放设备变更 |
| `CreatePlayoutVolumeChange(volume)` | 通知播放音量变更 |
| `CreateCustomRenderSetting(payload)` | 自定义渲染设置 |
| `CreateCaptureOutputUsedSetting(bool)` | 通知采集输出是否被使用 |

Type 枚举：`kNotSpecified`, `kCapturePreGain`, `kCaptureCompressionGain`, `kCaptureFixedPostGain`, `kPlayoutVolumeChange`, `kCustomRenderProcessingRuntimeSetting`, `kPlayoutAudioDeviceChange`, `kCapturePostGain`, `kCaptureOutputUsed`

### 辅助类

**StreamConfig**
| 方法 | 说明 |
|------|------|
| `StreamConfig(sample_rate_hz, num_channels)` | 构造流配置，自动计算帧大小 |
| `sample_rate_hz()` / `num_channels()` / `num_frames()` / `num_samples()` | 获取属性 |

**ProcessingConfig**
| 方法 | 说明 |
|------|------|
| `input_stream()` / `output_stream()` | 采集输入/输出配置 |
| `reverse_input_stream()` / `reverse_output_stream()` | 渲染输入/输出配置 |

### 接口定义

**EchoDetector**（回声检测器接口）
| 方法 | 说明 |
|------|------|
| `Initialize(...)` | 初始化（采集和渲染的采样率/声道数） |
| `AnalyzeRenderAudio(render_audio)` | 分析渲染音频 |
| `AnalyzeCaptureAudio(capture_audio)` | 分析采集音频 |
| `GetMetrics()` | 获取检测指标（echo_likelihood） |

**CustomAudioAnalyzer**
| 方法 | 说明 |
|------|------|
| `Initialize(sample_rate_hz, num_channels)` | 初始化 |
| `Analyze(const AudioBuffer*)` | 分析信号（不改变） |

**CustomProcessing**
| 方法 | 说明 |
|------|------|
| `Initialize(sample_rate_hz, num_channels)` | 初始化 |
| `Process(AudioBuffer*)` | 处理信号（可修改） |
| `SetRuntimeSetting(RuntimeSetting)` | 处理运行时设置 |

**AudioProcessingBuilderInterface**
| 方法 | 说明 |
|------|------|
| `Build(const Environment&)` | 创建 APM 实例 |

### 枚举

**NativeRate**
| 值 | 说明 |
|----|------|
| `kSampleRate8kHz` | 8000 Hz |
| `kSampleRate16kHz` | 16000 Hz |
| `kSampleRate32kHz` | 32000 Hz |
| `kSampleRate48kHz` | 48000 Hz |

**Error**
| 值 | 说明 |
|----|------|
| `kNoError` / `kUnspecifiedError` / `kCreationFailedError` / `kUnsupportedComponentError` / `kUnsupportedFunctionError` / `kNullPointerError` / `kBadParameterError` / `kBadSampleRateError` / `kBadDataLengthError` / `kBadNumberChannelsError` / `kFileError` / `kStreamParameterNotSetError` / `kNotEnabledError` | 致命错误 |
| `kBadStreamParameterWarning` | 非致命警告（参数越界时自动截断） |

## 实现文件 (.cc)

### 配置序列化 - `Config::ToString()`

使用 `SimpleStringBuilder` 将完整配置序列化为人类可读的字符串，包含所有子模块状态，用于日志和调试。

### 辅助类型别名

```cpp
using Agc1Config = AudioProcessing::Config::GainController1;
using Agc2Config = AudioProcessing::Config::GainController2;
```

### 枚举转字符串

- `NoiseSuppressionLevelToString()`: 将噪声抑制等级（kLow/kModerate/kHigh/kVeryHigh）转为字符串。
- `GainController1ModeToString()`: 将 AGC1 模式（AdaptiveAnalog/AdaptiveDigital/FixedDigital）转为字符串。

### 比较运算符

实现了 `GainController1`、`GainController2`（含 `AdaptiveDigital`、`InputVolumeController`）、`CaptureLevelAdjustment`（含 `AnalogMicGainEmulation`）的 `operator==` 和 `operator!=`，用于配置比较和测试。

### CustomAudioProcessing

- 接收一个已存在的 `AudioProcessing` 实例，返回一个 Builder，其 `Build()` 方法直接返回该实例（忽略 `Environment` 参数）。
- 使用内部匿名类 `Builder` 实现 `AudioProcessingBuilderInterface`。
- `nullptr` 输入会导致 `RTC_CHECK` 失败。

### 运行时设置实现

- `PreAmplifier` 和 `CaptureLevelAdjustment` 使用 `CaptureLevelAdjustment::AnalogMicGainEmulation` 模拟模拟麦克风增益调整。
- 运行时设置通过 `RuntimeSetting` 的 union 存储不同类型值，使用类型安全的 Getter 方法读取。

## 学习扩展

### 典型使用流程

```cpp
// 1. 构建配置
AudioProcessing::Config config;
config.echo_canceller.enabled = true;
config.noise_suppression.enabled = true;
config.gain_controller1.enabled = true;

// 2. 创建 APM 实例
auto apm = BuiltinAudioProcessingBuilder(config).Build(CreateEnvironment());

// 3. 处理渲染帧（反向流）
apm->ProcessReverseStream(render_frame);

// 4. 处理采集帧（主流）
apm->set_stream_delay_ms(delay);
apm->set_stream_analog_level(analog_level);
apm->ProcessStream(capture_frame);

// 5. 获取输出状态
int new_analog_level = apm->recommended_stream_analog_level();
AudioProcessingStats stats = apm->GetStatistics();
```

### 子模块处理顺序

```
Capture Pipeline:
  输入 → PreAmplifier → CaptureLevelAdjustment → HPF → AEC → NS → AGC → 输出

Render Pipeline:
  输入 → AEC 参考信号分析 → 输出（不经其他处理）
```

### 多声道支持

- 渲染多声道通过 `Config::pipeline.multi_channel_render` 控制。
- 采集多声道（AEC3 激活时）通过 `Config::pipeline.multi_channel_capture` 控制。
- 多声道 downmix 支持平均声道和使用第一声道两种方式。

### AEC 移动模式 vs 标准模式

- **标准模式（mobile_mode=false）**：使用 AEC3，高性能需求，适合桌面和高端移动设备。
- **移动模式（mobile_mode=true）**：简化版 AEC，降低计算复杂度，适合低端移动设备。

### AGC1 vs AGC2

- **AGC1（传统）**：三种模式（模拟自适应/数字自适应/固定数字），包含 Clipping Predictor。
- **AGC2（新一代）**：由输入音量控制器、自适应数字控制器、固定数字控制器和限幅器组成，逐步替代 AGC1。
