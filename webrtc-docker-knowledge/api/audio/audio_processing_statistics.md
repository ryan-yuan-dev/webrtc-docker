# audio_processing_statistics

## 概述

`audio_processing_statistics` 定义了 `AudioProcessingStats` 结构体，用于封装 APM（Audio Processing Module）的音频处理统计信息。这些统计信息通过 `AudioProcessing::GetStatistics()` 获取，涵盖回声消除性能（ERL/ERLE）、延迟估计、残差回声检测、语音活动检测等指标。

## 头文件接口 (.h)

### 结构体 AudioProcessingStats

标记为 `RTC_EXPORT`，包含的字段均使用 `std::optional` 封装，表示该指标可能在某些条件下不可用。

| 字段 | 类型 | 说明 |
|------|------|------|
| `voice_detected` | `std::optional<bool>` | **已废弃**。最后一帧处理后是否检测到语音。仅在 VAD 启用时报告。 |
| `echo_return_loss` | `std::optional<double>` | ERL = 10log10(P_far / P_echo)，回声返回损失 |
| `echo_return_loss_enhancement` | `std::optional<double>` | ERLE = 10log10(P_echo / P_out)，回声返回损失增强 |
| `divergent_filter_fraction` | `std::optional<double>` | AEC 线性滤波器发散的时间比例（1 秒滑动窗口） |
| `delay_median_ms` | `std::optional<int32_t>` | 延迟估计中位数（ms），首次调用 GetStatistics() 后以 1 秒为聚合窗口 |
| `delay_standard_deviation_ms` | `std::optional<int32_t>` | 延迟估计标准差（ms） |
| `residual_echo_likelihood` | `std::optional<double>` | 残差回声检测器似然度 |
| `residual_echo_likelihood_recent_max` | `std::optional<double>` | 最近时段的最大残差回声似然度 |
| `delay_ms` | `std::optional<int32_t>` | AEC 瞬时延迟估计（ms），调用 GetStatistics() 时的瞬时值 |

## 实现文件 (.cc)

实现非常简洁，仅包含默认构造/拷贝构造/析构函数，全部使用 `= default`：

```cpp
AudioProcessingStats::AudioProcessingStats() = default;
AudioProcessingStats::AudioProcessingStats(const AudioProcessingStats& other) = default;
AudioProcessingStats::~AudioProcessingStats() = default;
```

由于存在 `[[deprecated]]` 的 `voice_detected` 字段，拷贝构造函数使用了 `#pragma clang diagnostic` 抑制废弃声明警告。

## 学习扩展

### ERL 与 ERLE 的含义

- **ERL (Echo Return Loss)**：衡量远端信号与回声信号之间的衰减比，值越大说明扬声器到麦克风的声学路径衰减越大，回声越小。
- **ERLE (Echo Return Loss Enhancement)**：衡量 AEC 处理后回声信号的衰减量，值越大说明 AEC 性能越好。

### 延迟估计

- `delay_median_ms` 和 `delay_standard_deviation_ms` 以 1 秒为聚合窗口。
- 初始状态（首次调用 GetStatistics() 前）是累积模式，首次调用后切换为 1 秒滑动窗口。
- 多客户端同时拉取统计信息时，首个调用会触发窗口切换。

### 残差回声

- `residual_echo_likelihood` 指示经 AEC 处理后残留回声的可能程度。
- `residual_echo_likelihood_recent_max` 记录近期峰值，用于检测瞬态回声问题。

### 用法

```cpp
auto apm = BuiltinAudioProcessingBuilder().Build(env);
// ... 处理音频 ...
AudioProcessingStats stats = apm->GetStatistics(/*has_remote_tracks=*/true);
if (stats.echo_return_loss.has_value()) {
  printf("ERL: %f dB\n", *stats.echo_return_loss);
}
if (stats.residual_echo_likelihood.has_value() &&
    *stats.residual_echo_likelihood > 0.5) {
  // 残差回声可能过大
}
```
