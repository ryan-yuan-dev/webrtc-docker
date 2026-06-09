# goog_cc_factory

## 概述

`goog_cc_factory.h` / `goog_cc_factory.cc` 定义了 Google Congestion Control (GoogCC) 网络控制器工厂的 API 入口。GoogCC 是 WebRTC 默认使用的拥塞控制算法，基于延迟梯度 (Trendline) 和丢包率 (Loss-based) 的混合方案。

该工厂封装了创建 `GoogCcNetworkController` 实例的细节，遵循 `NetworkControllerFactoryInterface` 接口约定，是 WebRTC 拥塞控制框架的插件化入口点。

## 头文件接口 (.h)

**文件**: `api/transport/goog_cc_factory.h`

### GoogCcFactoryConfig

```cpp
struct GoogCcFactoryConfig {
  std::unique_ptr<NetworkStateEstimatorFactory> network_state_estimator_factory;
  NetworkStatePredictorFactoryInterface* network_state_predictor_factory = nullptr;
};
```

- **network_state_estimator_factory**: 可选的网络状态估计器工厂，用于创建链路容量估计器
- **network_state_predictor_factory**: 可选的网络状态预测器工厂，用于预测网络状态变化

### GoogCcNetworkControllerFactory

```cpp
class RTC_EXPORT GoogCcNetworkControllerFactory
    : public NetworkControllerFactoryInterface {
 public:
  GoogCcNetworkControllerFactory() = default;
  explicit GoogCcNetworkControllerFactory(GoogCcFactoryConfig config);

  std::unique_ptr<NetworkControllerInterface> Create(
      NetworkControllerConfig config) override;
  TimeDelta GetProcessInterval() const override;
};
```

- 继承自 `NetworkControllerFactoryInterface`，是拥塞控制框架的标准工厂接口
- `Create(config)`: 创建 `GoogCcNetworkController` 实例
- `GetProcessInterval()`: 返回拥塞控制器的处理间隔（25ms）

## 实现文件 (.cc)

**文件**: `api/transport/goog_cc_factory.cc`

### Create 方法

```cpp
std::unique_ptr<NetworkControllerInterface>
GoogCcNetworkControllerFactory::Create(NetworkControllerConfig config) {
  GoogCcConfig goog_cc_config;
  if (factory_config_.network_state_estimator_factory) {
    goog_cc_config.network_state_estimator =
        factory_config_.network_state_estimator_factory->Create(
            &config.env.field_trials());
  }
  if (factory_config_.network_state_predictor_factory) {
    goog_cc_config.network_state_predictor =
        factory_config_.network_state_predictor_factory
            ->CreateNetworkStatePredictor();
  }
  return std::make_unique<GoogCcNetworkController>(config,
                                                   std::move(goog_cc_config));
}
```

- 从 `factory_config_` 中读取可选工厂，实例化网络状态估计器和预测器
- 最终创建 `GoogCcNetworkController` 并返回

### GetProcessInterval

```cpp
TimeDelta GoogCcNetworkControllerFactory::GetProcessInterval() const {
  const int64_t kUpdateIntervalMs = 25;
  return TimeDelta::Millis(kUpdateIntervalMs);
}
```

- 返回固定 25ms 的处理间隔
- 拥塞控制器每 25ms 执行一次更新逻辑（如码率计算）

### 构造函数

```cpp
GoogCcNetworkControllerFactory::GoogCcNetworkControllerFactory(
    GoogCcFactoryConfig config)
    : factory_config_(std::move(config)) {}
```

- 通过 move 语义接收配置，避免拷贝

## 学习扩展

### GoogCC 拥塞控制算法概览

GoogCC (Google Congestion Control) 是 WebRTC 默认的拥塞控制算法，定义在 RFC 8836 和 RFC 8837 中。

```
GoogCC 核心组件

┌─────────────────────────────────────┐
│  GoogCcNetworkController            │
│  ├── 延迟梯度估计 (Trendline)        │
│  │   基于接收端延迟的线性趋势判断网络  │
│  │   是否开始拥塞                     │
│  ├── 丢包检测 (Loss-based)           │
│  │   当丢包率超过阈值时降低码率        │
│  ├── 码率决策 (Acknowledged Bitrate) │
│  │   综合延迟和丢包信息计算目标码率    │
│  └── 探测 (Probe)                   │
│      发送探测包检测可用带宽上限        │
└─────────────────────────────────────┘
```

### GoogCC 与其他控制器的比较

| 特性 | GoogCC | REMB | TransportCC |
|------|--------|------|-------------|
| 延迟估计 | Trendline 滤波器 | Kalman 滤波器 | Trendline 滤波器 |
| 反馈方式 | TransportFeedback (TWCC) | REMB RTCP | TransportFeedback |
| 计算端 | 发送端 | 接收端 | 发送端 |
| 默认启用 | WebRTC 默认 | 旧版兼容 | 实验性 |

### 25ms 处理间隔的设计理由

- 25ms 约等于一个视频帧的间隔（40fps），与视频帧率匹配
- 间隔太小会增加 CPU 开销，太大则响应迟钝
- 这是"至少每 25ms"的意思，实际触发可能更频繁（如收到反馈包时）

## 设计模式

| 模式 | 出现位置 | 说明 |
|------|----------|------|
| **Factory Method** | `GoogCcNetworkControllerFactory::Create` | 封装拥塞控制器创建逻辑，调用方只需提供配置 |
| **Strategy / Plugin** | `NetworkControllerFactoryInterface` | 拥塞控制算法可替换，通过工厂接口实现多态 |
| **Dependency Injection** | `GoogCcFactoryConfig` | 通过网络状态估计器/预测器工厂注入依赖 |
