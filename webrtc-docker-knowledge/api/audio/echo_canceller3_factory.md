# echo_canceller3_factory

## 概述

`echo_canceller3_factory` 定义了 `EchoCanceller3Factory` 类，实现了 `EchoControlFactory` 接口，用于创建 AEC3（Echo Canceller 3）回声消除器实例。该工厂将 AEC3 的配置参数（包括多声道配置）封装起来，通过 `Create()` 方法生成具体回声控制实例。

## 头文件接口 (.h)

### 类 EchoCanceller3Factory

继承 `EchoControlFactory`，标记为 `RTC_EXPORT`。

| 方法 | 说明 |
|------|------|
| `EchoCanceller3Factory()` | 默认构造，使用默认 AEC3 配置 |
| `EchoCanceller3Factory(const EchoCanceller3Config&)` | 指定 AEC3 配置 |
| `EchoCanceller3Factory(config, multichannel_config)` | 指定配置 + 多声道配置 |
| `Create(env, sample_rate, render_channels, capture_channels)` | 创建 EchoControl 实例 |
| `Create(env, sample_rate, render_channels, capture_channels, neural_residual_echo_estimator)` | 创建时注入神经残差回声估计器 |

### 私有成员

| 成员 | 类型 | 说明 |
|------|------|------|
| `config_` | `const EchoCanceller3Config` | AEC3 配置 |
| `multichannel_config_` | `const std::optional<EchoCanceller3Config>` | 多声道配置（可选） |

## 实现文件 (.cc)

### Create() 方法实现

```cpp
absl_nonnull std::unique_ptr<EchoControl> EchoCanceller3Factory::Create(
    const Environment& env,
    int sample_rate_hz,
    int num_render_channels,
    int num_capture_channels) {
  return std::make_unique<EchoCanceller3>(
      env, config_, multichannel_config_,
      /*neural_residual_echo_estimator=*/nullptr, sample_rate_hz,
      num_render_channels, num_capture_channels);
}
```

- 委托给 `EchoCanceller3` 构造函数创建具体实例。
- 注入 `NeuralResidualEchoEstimator` 的重载允许 AEC3 使用神经网络增强的残差回声估计。

## 学习扩展

### 与 BuiltinAudioProcessingBuilder 的关系

当通过 `BuiltinAudioProcessingBuilder::SetEchoControlFactory()` 注入 `EchoCanceller3Factory` 时，Builder 会将此工厂传递给 `AudioProcessingImpl`，后者在初始化 AEC 模块时调用工厂的 `Create()` 方法。如果同时设置了 `SetEchoCancellerConfig()` 和 `SetEchoControlFactory()`，自定义工厂优先级更高，config 配置被忽略。

### 使用场景

```cpp
EchoCanceller3Config config;
// 调整自定义参数...
EchoCanceller3Config multichannel_cfg =
    EchoCanceller3Config::CreateDefaultMultichannelConfig();

auto apm = BuiltinAudioProcessingBuilder()
    .SetEchoControlFactory(std::make_unique<EchoCanceller3Factory>(
        config, multichannel_cfg))
    .Build(env);
```

### 工厂模式设计

`EchoControlFactory` 是抽象工厂接口，`EchoCanceller3Factory` 是其具体实现。这种设计允许：
1. 用户使用 WebRTC 内置的 AEC3 实现。
2. 用户也可以实现自定义 `EchoControlFactory` 来注入自己的回声消除器。
3. APM 内部通过工厂接口解耦回声消除器的创建逻辑。
