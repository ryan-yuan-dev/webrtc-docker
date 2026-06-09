# audio_frame

## 概述

`audio_frame` 定义了 WebRTC 音频处理管线的核心数据结构 `AudioFrame`，用于在音频模块之间传递 PCM 音频数据。它位于 `api/audio/` 目录，是 WebRTC public API 的一部分，被音频处理模块 (APM)、编解码器、音频设备层等广泛使用。

AudioFrame 存储最多 120 ms 的 super-wideband（32 kHz）立体声音频数据，支持单声道到多声道（最多 24 通道）的音频帧。该结构同时维护音频元数据，包括时间戳、VAD 活动状态、语音类型和 RTP 包信息。

> **注意**：官方注释指出 AudioFrame 是 "de-facto api"，计划 overhaul 甚至替换，不建议外部接口依赖。

## 头文件接口 (.h)

### 常量

| 常量名 | 类型 | 值 | 说明 |
|--------|------|-----|------|
| `kDefaultAudioBufferLengthMs` | `constexpr size_t` | 10u | 默认每帧音频时长 10 ms |
| `kDefaultAudioBuffersPerSec` | `constexpr size_t` | 100u | 每秒音频帧数（10ms 一帧） |
| `kMaxDataSizeSamples` | `enum : size_t` | 7680 | 最大采样点数量 |
| `kMaxDataSizeBytes` | `enum : size_t` | `kMaxDataSizeSamples * sizeof(int16_t)` | 最大字节数 |

### 辅助函数

| 函数 | 说明 |
|------|------|
| `SampleRateToDefaultChannelSize(sample_rate)` | 根据采样率计算 10ms 的单通道采样点数 |

### 枚举

**VADActivity**
| 值 | 含义 |
|----|-------|
| `kVadActive` (0) | 语音激活 |
| `kVadPassive` (1) | 语音非激活 |
| `kVadUnknown` (2) | 未知 |

**SpeechType**
| 值 | 含义 |
|----|-------|
| `kNormalSpeech` (0) | 正常语音 |
| `kPLC` (1) | Packet Loss Concealment (丢包隐藏) |
| `kCNG` (2) | Comfort Noise Generation (舒适噪声) |
| `kPLCCNG` (3) | PLC + CNG 组合 |
| `kCodecPLC` (5) | 编解码器级 PLC |
| `kUndefined` (4) | 未定义 |

### 类 AudioFrame

| 方法 / 属性 | 说明 |
|-------------|------|
| `AudioFrame()` | 默认构造函数，buffer 初始为静音态 |
| `AudioFrame(sample_rate_hz, num_channels, layout)` | 带参数构造，自动计算 10ms 帧大小，自动推导 channel layout |
| `Reset()` | 重置所有成员为默认状态，置为静音 |
| `ResetWithoutMuting()` | 重置但不改变静音状态（避免不必要的 buffer 清零） |
| `UpdateFrame(...)` | 用外部数据更新帧内容 |
| `CopyFrom(src)` | 从另一个 AudioFrame 复制 |
| `data()` | 返回只读数据指针（静音时返回全零 buffer） |
| `data_view()` | 返回 `InterleavedView<const int16_t>` 只读视图 |
| `mutable_data()` | 返回可写数据指针（首次调用会清零并取消静音） |
| `mutable_data(samples_per_channel, num_channels)` | 带维度参数的可写视图，同时更新内部状态 |
| `Mute()` | 将帧标记为静音 |
| `muted()` | 返回是否静音 |
| `SetLayoutAndNumChannels(layout, num_channels)` | 设置声道布局和数量 |
| `SetSampleRateAndChannelSize(sample_rate)` | 设置采样率并计算 10ms 默认帧大小 |

**关键公共成员变量**
| 变量 | 类型 | 说明 |
|------|------|------|
| `timestamp_` | `uint32_t` | 第一个采样点的 RTP 时间戳 |
| `elapsed_time_ms_` | `int64_t` | 自首帧以来的时间（ms），-1 表示未初始化 |
| `ntp_time_ms_` | `int64_t` | 估计捕获时间的 NTP 时间（ms） |
| `samples_per_channel_` | `size_t` | 每通道采样点数 |
| `sample_rate_hz_` | `int` | 采样率 |
| `num_channels_` | `size_t` | 声道数 |
| `speech_type_` | `SpeechType` | 语音类型 |
| `vad_activity_` | `VADActivity` | VAD 活动状态 |
| `packet_infos_` | `RtpPacketInfos` | 组成此帧的 RTP 包信息（用于 getContributingSources） |

## 实现文件 (.cc)

### 构造函数

- **默认构造函数**：通过 `static_assert` 验证 `data_` 大小与 `kMaxDataSizeBytes` 一致。
- **带参构造函数**：计算默认 10ms 的 `samples_per_channel_`；若 `layout` 为 `CHANNEL_LAYOUT_UNSUPPORTED`，则通过 `GuessChannelLayout()` 自动推导声道布局。

### Reset / ResetWithoutMuting

- `Reset()` 调用 `ResetWithoutMuting()` 后再将 `muted_` 置为 `true`。
- `ResetWithoutMuting()` 重置所有成员变量但不触及 `muted_` 标志，避免后续写操作时多余清零。

### UpdateFrame

- 从外部 `const int16_t* data` 拷贝数据到内部 buffer。
- 调用 `GuessChannelLayout(num_channels)` 自动推导声道布局。
- 当 `data` 为 `nullptr` 时，帧被标记为静音而非拷贝数据。

### CopyFrom

- 从另一个 AudioFrame 拷贝所有元数据和音频样本。
- 处理自赋值情况（`this == &src` 时直接返回）。
- 如果当前帧静音而源帧非静音，会先通过 `ClearSamples` 清零 buffer 再拷贝（避免 MSAN 告警）。

### data() / data_view()

- `data()` 在静音时返回一个全局静态零 buffer 的指针（`zeroed_data()`），否则返回内部 `data_` 指针。
- `data_view()` 返回 `InterleavedView<const int16_t>` 视图。

### mutable_data()

- 若帧处于静音态，先使用 `ClearSamples` 清零内部 buffer，再将 `muted_` 设为 `false`，最后返回 buffer 指针。
- 带参数的版本同时更新 `samples_per_channel_` 和 `num_channels_`，并包含严格的范围检查与参数校验。

### 零 buffer 实现

```cpp
static ArrayView<const int16_t> AudioFrame::zeroed_data() {
  static int16_t* null_data = new int16_t[kMaxDataSizeSamples]();
  return ArrayView<const int16_t>(null_data, kMaxDataSizeSamples);
}
```

使用 `static` 变量确保整个进程共用一个零 buffer，避免为每个静音帧都分配内存。

## 学习扩展

### 调用关系

- AudioFrame 是 `AudioProcessing::ProcessStream()` 和 `ProcessReverseStream()` 的输入/输出载体（int16 接口）。
- 音频编解码器解码后的 PCM 数据填充到 AudioFrame 中。
- 音频设备层的采集数据先放入 AudioFrame，再送入处理管线。
- `RtpPacketInfos` 用于 SourceTracker 实现 `RTCRtpReceiver.getContributingSources()` 的 WebRTC 标准接口。

### 使用示例

```cpp
// 创建 16kHz 单声道 10ms 帧
AudioFrame frame(16000, 1);
auto view = frame.mutable_data(160, 1);  // 160 samples per channel
// 填入音频数据...
frame.set_absolute_capture_timestamp_ms(TimeMillis());
frame.timestamp_ = rtp_timestamp;

// 送入 APM 处理
apm->ProcessStream(frame);
```

### 相关概念

- **Interleaved 布局**：立体声数据以 L, R, L, R, ... 交替排列的存储方式。
- **RTP 时间戳**：用于音频同步和抖动缓冲管理，与采样率相关。
- **Packet Loss Concealment (PLC)**：丢包时的音频帧隐藏技术，通过预测生成替代帧。
- **Comfort Noise Generation (CNG)**：在无声期生成低电平噪声避免突兀静音。
