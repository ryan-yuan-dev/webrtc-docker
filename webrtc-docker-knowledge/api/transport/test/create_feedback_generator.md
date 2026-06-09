# create_feedback_generator

## 概述

`create_feedback_generator.h` / `create_feedback_generator.cc` 提供了创建拥塞控制反馈生成器 (FeedbackGenerator) 的工厂函数。反馈生成器是 WebRTC 传输层测试框架的一部分，用于模拟网络拥塞控制场景中的传输反馈数据。

该模块提供了两种类型的反馈生成器：
- **FeedbackGenerator**: 完整的网络仿真，包括实际的包发送和反馈收集
- **FeedbackGeneratorWithoutNetwork**: 在不模拟完整网络的情况下生成反馈数据，依赖外部的 `NetworkEmulationManager`

## 头文件接口 (.h)

**文件**: `api/transport/test/create_feedback_generator.h`

```cpp
namespace webrtc {

std::unique_ptr<FeedbackGenerator> CreateFeedbackGenerator(
    FeedbackGenerator::Config confg);

std::unique_ptr<FeedbackGeneratorWithoutNetwork>
CreateFeedbackGeneratorWithoutNetwork(
    FeedbackGeneratorWithoutNetwork::Config config,
    NetworkEmulationManager& network_emulation_manager);

}  // namespace webrtc
```

有两个重载：
1. `CreateFeedbackGenerator`: 创建完整的反馈生成器，包含内部网络仿真
2. `CreateFeedbackGeneratorWithoutNetwork`: 创建无网络仿真的反馈生成器，需要外部注入 `NetworkEmulationManager`

## 实现文件 (.cc)

**文件**: `api/transport/test/create_feedback_generator.cc`

```cpp
namespace webrtc {

std::unique_ptr<FeedbackGenerator> CreateFeedbackGenerator(
    FeedbackGenerator::Config confg) {
  return std::make_unique<FeedbackGeneratorImpl>(confg);
}

std::unique_ptr<FeedbackGeneratorWithoutNetwork>
CreateFeedbackGeneratorWithoutNetwork(
    FeedbackGeneratorWithoutNetwork::Config config,
    NetworkEmulationManager& network_emulation_manager) {
  return std::make_unique<FeedbackGeneratorWithoutNetworkImpl>(
      config, network_emulation_manager);
}

}  // namespace webrtc
```

两个工厂函数分别实例化：
- `FeedbackGeneratorImpl`: 定义在 `test/network/feedback_generator.h` 中的完整实现
- `FeedbackGeneratorWithoutNetworkImpl`: 简化版本，依赖外部网络仿真管理器

## 学习扩展

### 反馈生成器在测试中的作用

反馈生成器模拟完整的端到端传输反馈数据流：

```
包发送 → 网络传输（延迟、丢包） → 接收端 → 生成 TransportFeedback
  ↑                                                   │
  │                   测试场景                         │
  └───────────────────────────────────────────────────┘
```

- 用于测试拥塞控制算法在特定网络条件下的表现
- 生成 `TransportPacketsFeedback` 数据，供 `GoogCcNetworkController` 消费

### FeedbackGenerator 接口

```cpp
class FeedbackGenerator {
 public:
  struct Config {
    // 发送码率、包大小、网络延迟等配置
  };
  virtual ~FeedbackGenerator() = default;
  virtual std::vector<TransportPacketsFeedback> CreateFeedback() = 0;
};
```

## 设计模式

| 模式 | 出现位置 | 说明 |
|------|----------|------|
| **Factory Method** | `CreateFeedbackGenerator` / `CreateFeedbackGeneratorWithoutNetwork` | 封装具体实现类的实例化 |
| **Strategy** | `FeedbackGenerator` / `FeedbackGeneratorWithoutNetwork` | 多种反馈生成策略，统一接口 |
