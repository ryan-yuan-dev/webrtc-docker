# audio_options

## 概述

`audio_options.h` / `audio_options.cc` 定义了 `AudioOptions` 结构体，用于配置 `VoiceMediaChannel` 或 `VoiceMediaEngine` 的音频处理选项。该结构体是 WebRTC 音频链路的统一配置入口，替代了旧有的分散式 flags 设计。

在 WebRTC 架构中，该文件位于 `api/` 层，是应用程序和音频引擎之间的配置契约。通过 `std::optional` 字段实现按需覆盖，每个可选字段的缺失值表示"不改变当前设置"。

## 头文件接口 (.h)

### 结构体 `AudioOptions`

| 成员 | 类型 | 说明 |
|------|------|------|
| `echo_cancellation` | `std::optional<bool>` | 声学回声消除 (AEC)，试图滤除后续入站拾音产生的输出信号 |
| `ios_force_software_aec_HACK` | `std::optional<bool>` | (仅 iOS) 强制使用软件 AEC，解决特定设备硬件 AEC 缺陷 |
| `auto_gain_control` | `std::optional<bool>` | 自动增益控制 (AGC)，动态调整本地麦克风灵敏度 |
| `noise_suppression` | `std::optional<bool>` | 噪声抑制 (NS)，滤除背景噪声 |
| `highpass_filter` | `std::optional<bool>` | 高通滤波器，移除低频背景噪声 |
| `stereo_swapping` | `std::optional<bool>` | 左右声道交换 |
| `audio_jitter_buffer_max_packets` | `std::optional<int>` | 音频接收端抖动缓冲区 (NetEq) 最大容量（packet 数） |
| `audio_jitter_buffer_fast_accelerate` | `std::optional<bool>` | NetEq 快速加速模式 |
| `audio_jitter_buffer_min_delay_ms` | `std::optional<int>` | NetEq 最小目标延迟（毫秒） |
| `audio_network_adaptor` | `std::optional<bool>` | 启用音频网络适配器 |
| `audio_network_adaptor_config` | `std::optional<std::string>` | 音频网络适配器的配置字符串 |
| `init_recording_on_send` | `std::optional<bool>` | 开始发送时预初始化 ADM 录音（即将移除） |

### 成员函数

| 函数 | 说明 |
|------|------|
| `SetAll(const AudioOptions& change)` | 将 `change` 中已设置的字段覆盖到当前实例，实现部分更新 |
| `operator==` / `operator!=` | 比较两个 AudioOptions 的所有字段是否相等 |
| `ToString()` | 将已设置的选项格式化为可读字符串（用于日志） |

## 实现文件 (.cc)

### SetAll 逻辑
使用模板函数 `SetFrom<T>(std::optional<T>* s, const std::optional<T>& o)`：仅当 `o` 有值时，才将 `o` 的值赋给 `s`。这使得调用方可以只传入需要修改的字段，无需填充所有选项。

### ToString 逻辑
使用 `ToStringIfSet<T>` 模板函数，只有在字段有值时才追加到输出字符串。输出使用简短键名（如 `"aec"`、`"agc"`、`"ns"`），节省日志空间。

## 学习扩展

- `AudioOptions` 与 WebRTC 标准的 `RTCRtpEncodingParameters` 中的 `adaptivePtime` 存在重叠，`audio_network_adaptor` 标记为待移除。
- 这些选项最终会传递到音频引擎层（`webrtc::AudioProcessing` 模块）以及 NetEq 抖动缓冲区。
- 应用程序通常在创建 `PeerConnectionFactory` 或在 `CreateAudioSource` 时设置这些选项。

## 设计模式

**聚合配置模式 (Aggregate Configuration)**：将所有音频相关配置聚合到一个结构体中，使用 `std::optional` 支持部分设置。`SetAll` 方法实现了部分更新模式，类似于 Builder 模式的变体，避免了繁重的构造函数参数列表。
