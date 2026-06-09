# WebRTC 音频模块 API 文档

## 概述

WebRTC 音频模块 (`api/audio/`) 定义了音频处理流水线的公共接口和数据结构。它是 WebRTC 音频栈的「契约层」——上层（如 PeerConnection）通过这里的接口与下层实现（如 `modules/audio_processing/`）交互。

音频处理的核心是 **APM (Audio Processing Module)**，它实现 3A 算法：**AEC (Acoustic Echo Cancellation，回声消除)**、**AGC (Automatic Gain Control，自动增益控制)**、**ANS (Adaptive Noise Suppression，降噪)**。

---

## 一、音频帧 — AudioFrame

### audio_frame.cc
**路径**: `api/audio/audio_frame.cc`
**关键类**: `AudioFrame`

`AudioFrame` 是 WebRTC 中表示一段 PCM 音频数据的核心数据结构。它类似于一个带元数据的音频缓冲区。

**关键成员**:
| 成员 | 类型 | 说明 |
|------|------|------|
| `data_` | `std::array<int16_t, 3840>` | 原始 PCM 采样数据 (16-bit interleaved) |
| `samples_per_channel_` | `size_t` | 每声道采样数 (典型值: 480/960 @ 48kHz) |
| `sample_rate_hz_` | `int` | 采样率 (Hz)，如 8000, 16000, 48000 |
| `num_channels_` | `size_t` | 声道数 (最多 8) |
| `channel_layout_` | `ChannelLayout` | 声道布局枚举 |
| `timestamp_` | `uint32_t` | RTP 时间戳 |
| `speech_type_` | `SpeechType` | 语音类型 (Normal/CNG/DTMF/Undefined) |
| `vad_activity_` | `VADActivity` | VAD (Voice Activity Detection) 活动性 |
| `muted_` | `bool` | 静音标志 |

**核心方法**:
- `UpdateFrame()` — 将外部 PCM 数据拷贝到帧中，自动推断声道布局
- `CopyFrom()` — 深拷贝另一个 AudioFrame（包括静音处理和 MSAN 安全处理）
- `Mute()` / `muted()` — 静音控制，muted 时 `data()` 返回零填充数组 (zeroed_data)
- `data_view()` — 返回 `InterleavedView<const int16_t>`，提供类型安全的交错视图
- `mutable_data()` — 获取可写数据指针，若 muted 则自动清零并取消 muted 状态
- `SetLayoutAndNumChannels()` — 同时设置声道布局和声道数
- `SetSampleRateAndChannelSize()` — 根据采样率自动设置预期帧大小

**扩展接口**: 通过 `audio_view.h` 支持三种数据视图：
- `DeinterleavedView` — 非交错视图（每声道独立缓冲区），适合 DSP 处理
- `InterleavedView` — 交错视图（LRLRLR...），适合音频硬件 I/O
- `AudioBufferView` — 统一抽象，可包装上述两种视图

**缓冲区大小**: `kMaxDataSizeSamples = 3840`，对应 48kHz 下 80ms 立体声数据——这是 WebRTC 中最大的帧长度边界。

**学习扩展 — WebRTC 音频处理帧大小**:
```
典型 10ms 帧 @ 48kHz:    480 samples (单声道), 960 samples (立体声)
典型 20ms 帧 @ 48kHz:    960 samples (单声道), 1920 samples (立体声)
最大 80ms 缓冲区:       3840 samples (立体声)
```

---

## 二、音频处理核心 — AudioProcessing

### audio_processing.cc
**路径**: `api/audio/audio_processing.cc`
**关键类**: `AudioProcessing::Config`, `CustomProcessing`, `AudioProcessingBuilderInterface`, `CustomAudioProcessing()`

这是 WebRTC 3A 处理的核心配置和接口入口。

**`AudioProcessing::Config`** — APM 的总配置结构，包含所有子模块开关和参数：

```
Config
├── PipelineConfig          # 流水线参数 (最大处理速率、多声道支持)
│   ├── maximum_internal_processing_rate
│   ├── multi_channel_render
│   └── multi_channel_capture
├── PreAmplifier            # 预放大器 (固定增益)
│   ├── enabled
│   └── fixed_gain_factor
├── CaptureLevelAdjustment  # 采集电平调节 (模拟麦克风增益仿真)
│   ├── enabled
│   ├── pre_gain_factor / post_gain_factor
│   └── AnalogMicGainEmulation (初始电平、启用标志)
├── HighPassFilter          # 高通滤波 (enabled)
├── EchoCanceller           # 回声消除 (enabled, mobile_mode)
├── NoiseSuppression        # 降噪 (enabled, Level: Low/Moderate/High/VeryHigh)
├── TransientSuppression    # 瞬态抑制 (enabled)
├── GainController1         # AGC1 (传统模拟/数字自适应)
└── GainController2         # AGC2 (新一代固定/自适应数字增益)
```

**`CustomProcessing`** — 自定义音频处理钩子。用户可以注入自定义处理逻辑到 APM 流水线中。`SetRuntimeSetting()` 允许运行时参数调整。

**设计模式 — Builder 模式**:
`AudioProcessingBuilderInterface` 和 `CustomAudioProcessing()` 演示了 Builder 模式。`CustomAudioProcessing()` 接受一个已构造的 `AudioProcessing` 对象，包装为 Builder——这样调用方可以完全控制构造过程，而不需要 WebRTC 提供工厂逻辑。

**`Config::ToString()`** — 将完整配置序列化为可读字符串，用于调试和日志输出。

### audio_processing_statistics.cc
**路径**: `api/audio/audio_processing_statistics.cc`
**关键结构**: `AudioProcessingStats`

运行时的 APM 统计信息，用于监控和诊断：
- 回声消除相关：echo return loss, echo return loss enhancement, residual echo likelihood
- 延迟相关：delay median/standard deviation (ms)

### builtin_audio_processing_builder.cc
**路径**: `api/audio/builtin_audio_processing_builder.cc`
**关键类**: `BuiltinAudioProcessingBuilder`

创建实际 APM 实现的工厂。`Build()` 方法实例化 WebRTC 内置的音频处理器。它将 Config 注入到底层 `AudioProcessingImpl`。

---

## 三、回声消除 — EchoCanceller3

### echo_canceller3_config.cc
**路径**: `api/audio/echo_canceller3_config.cc`
**关键类**: `EchoCanceller3Config`

**AEC3 (Echo Canceller 3)** 是 WebRTC 的第三代回声消除器。此文件提供完整的配置参数结构和验证逻辑。

**配置层级结构**:
```
EchoCanceller3Config
├── Delay                    # 延迟估计器
│   ├── default_delay        # 默认延迟 (ms)
│   ├── down_sampling_factor # 降采样因子 (4 或 8)
│   ├── num_filters          # 延迟估计滤波器数量
│   └── fixed_capture_delay_samples  # 固定采集延迟 (samples)
├── Filter                   # 自适应滤波器
│   ├── refined              # 精炼滤波器 (收敛后)
│   │   ├── length_blocks    # 滤波器长度 (blocks)
│   │   ├── leakage_*        # 泄漏因子 (收敛/发散时)
│   │   ├── error_floor/ceil # 误差下界/上界
│   │   └── noise_gate       # 噪声门限
│   ├── refined_initial      # 初始精炼滤波器
│   ├── coarse               # 粗滤波器
│   └── coarse_initial       # 初始粗滤波器
├── Erle                     # ERLE (Echo Return Loss Enhancement) 估计
├── EpStrength               # 回声路径强度
├── EchoAudibility           # 回声可听性控制
├── RenderLevels             # 渲染信号电平
├── EchoModel                # 回声模型
├── ComfortNoise             # 舒适噪声
└── Suppressor               # 回声抑制器
    ├── normal_tuning        # 常态调谐 (非双讲情况)
    ├── nearend_tuning       # 近端调谐 (双讲情况)
    ├── dominant_nearend_detection
    ├── subband_nearend_detection
    ├── high_bands_suppression
    └── high_frequency_suppression
```

**关键方法**:
- `Validate()` — 参数校验和自动修正。对每个参数进行 clamp 操作，确保在合理范围内。返回 `false` 表示有参数被自动修正。
- `CreateDefaultMultichannelConfig()` — 为多声道场景创建优化的默认配置（更短的粗滤波器、更快的自适应速率、更保守的抑制器）。

**学习扩展 — AEC3 如何工作**:
```
远端信号(扬声器) ──→ 自适应滤波器 ──→ 估计回声
                        ↑
近端信号(麦克风) ──→ ──┼──→ 减法器 ──→ 残差 (去回声后的近端信号)
                        ↓
                  延迟估计器 (对齐远近端)
```

AEC3 使用 **粗-精两级滤波器**策略：
1. **粗滤波器 (Coarse)**: 快速自适应，覆盖大致回声估计
2. **精炼滤波器 (Refined)**: 慢速但精确，最终残差回声去除

双讲 (Double-Talk) 检测是关键挑战——当远近端同时说话时，自适应滤波器可能发散。AEC3 通过 `dominant_nearend_detection` 和复杂的抑制器调谐来解决。

### echo_canceller3_factory.cc
**路径**: `api/audio/echo_canceller3_factory.cc`
**关键类**: `EchoCanceller3Factory`

AEC3 工厂，实现 `EchoControlFactory` 接口。将 `EchoCanceller3Config` 注入到 AEC3 实现中。支持通过环境变量 `WEBRTC_USE_CREATIVE_AEC3` 选择实验性 AEC3 变体。

### echo_detector_creator.cc
**路径**: `api/audio/echo_detector_creator.cc`
**关键类**: 实现 `EchoDetectorCreator` 接口

创建残余回声检测器 (Residual Echo Detector)。当 AEC 仍然存在残余回声时，此检测器可以在流水线后期识别回声残留，触发额外的处理。

---

## 四、声道布局 — ChannelLayout

### channel_layout.cc
**路径**: `api/audio/channel_layout.cc`

定义 WebRTC 支持的声道布局体系和相关转换函数。

**支持的布局** (来自 `channel_layout.h` 枚举):

| 布局 | 声道数 | 典型用途 |
|------|--------|----------|
| `CHANNEL_LAYOUT_NONE` | 0 | 未使用/无效 |
| `CHANNEL_LAYOUT_MONO` | 1 | 单声道 |
| `CHANNEL_LAYOUT_STEREO` | 2 | 立体声 |
| `CHANNEL_LAYOUT_SURROUND` | 3 | 环绕声 (L, R, C) |
| `CHANNEL_LAYOUT_5_1` | 6 | 5.1 环绕 |
| `CHANNEL_LAYOUT_7_1` | 8 | 7.1 环绕 |
| `CHANNEL_LAYOUT_DISCRETE` | 0* | 离散声道 (声道数不固定) |
| `CHANNEL_LAYOUT_BITSTREAM` | 0 | 比特流 (如 Dolby/DTS 原始数据) |

**核心函数**:
- `ChannelLayoutToChannelCount(layout)` — 布局 → 声道数映射（查表法，O(1)）
- `GuessChannelLayout(channels)` — 声道数 → 最佳猜测布局（1→MONO, 2→STEREO, 6→5.1 等）
- `ChannelOrder(layout, channel)` — 获取特定声道在交错数据中的位置。用于声道重排。
- `ChannelLayoutToString(layout)` — 枚举 → 可读字符串（调试用）

**声道排序**:
`kChannelOrderings` 二维数组定义了每个布局中各声道的交错顺序。遵循 FFmpeg 的声道排序约定：
```
5.1 排列: FL(0), FR(1), FC(2), LFE(3), SL(4), SR(5)
7.1 排列: FL(0), FR(1), FC(2), LFE(3), SL(4), SR(5), BL(6), BR(7)
```
11 种声道类型：FL, FR, FC, LFE, BL, BR, FLofC, FRofC, BC, SL, SR

---

## 五、音频设备 — AudioDeviceModule

### create_audio_device_module.cc
**路径**: `api/audio/create_audio_device_module.cc`
**关键函数**: `CreateAudioDeviceModule()`

创建平台适配的 Audio Device Module (ADM) 的工厂函数。ADM 封装了音频 I/O：
- 麦克风采集 (capture)
- 扬声器播放 (render/playout)
- 平台相关实现 (AudioUnit/macOS, ALSA/Linux, WASAPI/Windows, OpenSLES/Android)

**设计模式 — Abstract Factory**:
`CreateAudioDeviceModule` 是一个典型的不带工厂类的抽象工厂简化形式。内部实现由 `modules/audio_device/` 中的平台相关代码提供。

---

## 学习扩展

### 音频处理流水线 (Audio Processing Pipeline)

```
┌──────────────────────────────────────────────────────────────┐
│                    AudioProcessing (APM)                      │
│                                                              │
│  远端音频                                                    │
│  (Render)                                                    │
│    │                                                         │
│    ├─→ [HighPassFilter] ─→ AEC 参考路径                       │
│    │         │                                               │
│    │         └─→ [EchoCanceller (AEC3)]                       │
│    │                  │                                      │
│  近端音频            │  (回声估计 & 消除)                       │
│  (Capture)           │                                       │
│    │                 │                                       │
│    ├─→ [HighPassFilter] ─┼─→ [AEC] ─→ [NoiseSuppression]     │
│    │                     │              │                    │
│    │                     │              └─→ [AGC]            │
│    │                     │                    │              │
│    │                     │                    └─→ 输出        │
│    │                     │                                   │
│    └─→ [TransientSuppression]                                │
│                                                              │
│  并行处理:                                                    │
│  [VAD]  ── 语音活动检测 (位于 AGC 模块中)                      │
│  [ResidualEchoDetector] ── 残余回声检测                        │
└──────────────────────────────────────────────────────────────┘
```

### 3A 算法概述

| 算法 | 全称 | 作用 | 实现位置 |
|------|------|------|----------|
| **AEC** | Acoustic Echo Cancellation | 消除扬声器到麦克风的回声 | `modules/audio_processing/aec3/` |
| **AGC** | Automatic Gain Control | 自动调节麦克风增益 | `modules/audio_processing/agc/` |
| **ANS** | Adaptive Noise Suppression | 降低背景噪声 | `modules/audio_processing/ns/` |

### 关键设计模式

| 模式 | 出现位置 | 说明 |
|------|----------|------|
| **Builder** | `AudioProcessingBuilderInterface` | 分步构建复杂对象 (APM) |
| **Strategy** | `CustomProcessing` | 允许注入自定义处理策略到流水线 |
| **Factory Method** | `EchoCanceller3Factory`, `CreateAudioDeviceModule` | 封装对象创建逻辑 |
| **Config Object** | `EchoCanceller3Config`, `AudioProcessing::Config` | 将配置从实现分离 |
| **Value Object** | `AudioFrame` | 不可变风格的数据传输对象 |
| **Facade** | `AudioProcessing` (interface) | 为复杂音频子系统提供简单入口 |
| **Observer** | `AudioProcessingStats` | 运行时可观测状态 |
| **Adapter/View** | `InterleavedView`, `DeinterleavedView` | 同一数据的多种访问方式 |
| **Enum as Config** | `ChannelLayout` | 声道布局的类型安全表示 |

### 性能考量

- **AudioFrame 内存布局**: `data_` 是固定大小数组（非堆分配），避免每次帧处理的 malloc 开销
- **AEC3 降采样**: `down_sampling_factor` 为 4 或 8，将 48kHz 降至 12kHz 或 6kHz 再处理，大幅减少计算量
- **粗-精滤波器**: 粗滤波器快速收敛但精度低；精炼滤波器精度高但收敛慢。二者配合实现快速响应+高精度
