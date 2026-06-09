# echo_detector_creator

## 概述

`echo_detector_creator` 定义了一个极简的工厂函数 `CreateEchoDetector()`，用于创建 WebRTC 的残差回声检测器（Residual Echo Detector）实例。该检测器用于监控 AEC 处理后的残差回声水平，提供 `AudioProcessingStats` 中的 `residual_echo_likelihood` 指标。

## 头文件接口 (.h)

### 函数

| 函数签名 | 说明 |
|----------|------|
| `CreateEchoDetector()` | 创建残差回声检测器实例，返回 `scoped_refptr<EchoDetector>` |

## 实现文件 (.cc)

### 实现逻辑

```cpp
scoped_refptr<EchoDetector> CreateEchoDetector() {
  return make_ref_counted<ResidualEchoDetector>();
}
```

创建 `ResidualEchoDetector` 实例，返回引用计数指针。`ResidualEchoDetector` 定义在 `modules/audio_processing/residual_echo_detector.h`。

## 学习扩展

### 与 APM 的关系

`CreateEchoDetector()` 创建的检测器通过 `BuiltinAudioProcessingBuilder::SetEchoDetector()` 注入到 APM 中：

```cpp
auto apm = BuiltinAudioProcessingBuilder()
    .SetEchoDetector(CreateEchoDetector())
    .Build(env);
// 后续可以通过 GetStatistics() 获取残差回声指标
AudioProcessingStats stats = apm->GetStatistics(true);
if (stats.residual_echo_likelihood.has_value()) {
  // 评估残差回声水平
}
```

### 残差回声检测的工作原理

`ResidualEchoDetector` 实现 `EchoDetector` 接口，通过比较渲染信号和采集信号的统计特性来估计残差回声可能性：
- `AnalyzeRenderAudio()`：分析远端渲染信号，提取信号特征。
- `AnalyzeCaptureAudio()`：分析近端采集信号，检测其中是否含有与渲染信号相关的成分。
- `GetMetrics()`：返回 `echo_likelihood` 和 `echo_likelihood_recent_max`。

### 与 AEC3 的关系

AEC3 内置了更复杂的回声消除机制，而残差回声检测器是独立于 AEC3 的轻量级模块：
- AEC3 主动消除回声。
- 残差回声检测器被动检测回声是否存在（无论是否经过 AEC 处理）。
- 两者可独立使用，检测器不依赖 AEC3。
