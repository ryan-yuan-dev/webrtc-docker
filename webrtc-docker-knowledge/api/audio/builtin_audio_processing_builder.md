# builtin_audio_processing_builder

## 概述

`builtin_audio_processing_builder` 定义了 WebRTC 内置 APM（Audio Processing Module）的工厂类 `BuiltinAudioProcessingBuilder`，实现了 `AudioProcessingBuilderInterface` 接口。它提供链式调用的 Builder 模式，用于配置和创建 `AudioProcessing` 实例。

该文件还声明了 `EchoControlFactory`（回声控制工厂）和 `NeuralResidualEchoEstimator` 的引用，允许注入自定义回声控制、采集/渲染处理模块、回声检测器等组件。

## 头文件接口 (.h)

### 类 BuiltinAudioProcessingBuilder

继承 `AudioProcessingBuilderInterface`，标记为 `RTC_EXPORT`。

| 方法 | 返回类型 | 说明 |
|------|----------|------|
| `BuiltinAudioProcessingBuilder()` | - | 默认构造函数（默认配置） |
| `BuiltinAudioProcessingBuilder(const Config&)` | - | 带初始配置的构造 |
| `SetConfig(const Config&)` | `BuiltinAudioProcessingBuilder&` | 设置 APM 配置（链式调用） |
| `SetEchoCancellerConfig(config, multichannel_config)` | `BuiltinAudioProcessingBuilder&` | 设置 AEC3 配置（注入自定义参数） |
| `SetEchoControlFactory(unique_ptr)` | `BuiltinAudioProcessingBuilder&` | 设置自定义回声控制工厂 |
| `SetCapturePostProcessing(unique_ptr)` | `BuiltinAudioProcessingBuilder&` | 设置采集后处理模块 |
| `SetRenderPreProcessing(unique_ptr)` | `BuiltinAudioProcessingBuilder&` | 设置渲染预处理模块 |
| `SetEchoDetector(scoped_refptr)` | `BuiltinAudioProcessingBuilder&` | 设置回声检测器 |
| `SetCaptureAnalyzer(unique_ptr)` | `BuiltinAudioProcessingBuilder&` | 设置采集分析器 |
| `SetNeuralResidualEchoEstimator(unique_ptr)` | `BuiltinAudioProcessingBuilder&` | 设置神经残差回声估计器 |
| `Build(const Environment&)` | `scoped_refptr<AudioProcessing>` | 创建最终 APM 实例 |

### 私有成员

| 成员 | 类型 | 说明 |
|------|------|------|
| `config_` | `AudioProcessing::Config` | APM 配置 |
| `echo_canceller_config_` | `std::optional<EchoCanceller3Config>` | AEC3 配置 |
| `echo_canceller_multichannel_config_` | `std::optional<EchoCanceller3Config>` | AEC3 多声道配置 |
| `echo_control_factory_` | `unique_ptr<EchoControlFactory>` | 自定回声控制工厂 |
| `capture_post_processing_` | `unique_ptr<CustomProcessing>` | 采集后处理 |
| `render_pre_processing_` | `unique_ptr<CustomProcessing>` | 渲染预处理 |
| `echo_detector_` | `scoped_refptr<EchoDetector>` | 回声检测器 |
| `capture_analyzer_` | `unique_ptr<CustomAudioAnalyzer>` | 采集分析器 |
| `neural_residual_echo_estimator_` | `unique_ptr<NeuralResidualEchoEstimator>` | 神经残差回声估计器 |

## 实现文件 (.cc)

### Build() 方法实现

```cpp
absl_nullable scoped_refptr<AudioProcessing>
BuiltinAudioProcessingBuilder::Build(const Environment& env) {
  return make_ref_counted<AudioProcessingImpl>(
      env, config_, echo_canceller_config_, echo_canceller_multichannel_config_,
      std::move(capture_post_processing_), std::move(render_pre_processing_),
      std::move(echo_control_factory_), std::move(echo_detector_),
      std::move(capture_analyzer_), std::move(neural_residual_echo_estimator_));
}
```

- 将 Builder 中设置的所有参数通过 `make_ref_counted<AudioProcessingImpl>` 转发给 `AudioProcessingImpl` 构造函数。
- 所有 `unique_ptr` 参数通过 `std::move` 转移所有权到 APM 实例。
- 返回的 `scoped_refptr<AudioProcessing>` 使用引用计数管理生命周期。

## 学习扩展

### Builder 模式

BuiltinAudioProcessingBuilder 使用典型的 Builder 设计模式：
1. 通过构造函数初始化默认或自定义配置。
2. 通过 Setter 方法链式注入可选组件。
3. 最终调用 `Build()` 方法组装并创建 APM 实例。

### 组件注入优先级

当 `echo_control_factory_` 被设置时（即注入自定义 `EchoControlFactory`），通过 `SetEchoCancellerConfig` 设置的 AEC3 配置将被忽略 — 自定义回声控制优先。

### 使用示例

```cpp
// 默认配置
auto apm = BuiltinAudioProcessingBuilder().Build(CreateEnvironment());

// 自定义配置 + 注入回声检测器
auto apm = BuiltinAudioProcessingBuilder(config)
    .SetEchoDetector(CreateEchoDetector())
    .SetConfig(updated_config)
    .Build(env);
```

### 与 AudioProcessingBuilderInterface 的关系

`AudioProcessingBuilderInterface` 是抽象工厂接口，仅定义 `Build(const Environment&)` 纯虚方法。`BuiltinAudioProcessingBuilder` 是其具体实现，用于创建 WebRTC 内置的 `AudioProcessingImpl` 实例。另一个实现 `CustomAudioProcessing` 用于注入外部创建的 APM 实例。
