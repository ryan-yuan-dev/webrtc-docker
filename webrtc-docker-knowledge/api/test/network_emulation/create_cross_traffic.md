# create_cross_traffic

## 概述

`create_cross_traffic` 模块提供创建交叉流量生成器的工厂函数。交叉流量用于在网络模拟测试中生成背景流量，模拟真实网络环境中的其他并发连接。支持随机游走、脉冲峰值和伪 TCP 三种交叉流量模式。

## 头文件接口 (.h)

### 工厂函数

| 函数 | 说明 |
|------|------|
| `CreateRandomWalkCrossTraffic(route, config)` | 随机游走交叉流量，流量速率在配置范围内随机变化 |
| `CreatePulsedPeaksCrossTraffic(route, config)` | 脉冲峰值交叉流量，周期性地产生短时高流量脉冲 |
| `CreateFakeTcpCrossTraffic(send_route, ret_route, config)` | 伪 TCP 交叉流量，模拟 TCP Reno 协议的拥塞控制行为 |

## 实现文件 (.cc)

- `CreateRandomWalkCrossTraffic` → 创建 `test::RandomWalkCrossTraffic`。
- `CreatePulsedPeaksCrossTraffic` → 创建 `test::PulsedPeaksCrossTraffic`。
- `CreateFakeTcpCrossTraffic` → 创建 `test::FakeTcpCrossTraffic`，需要发送路由和返回路由。

## 学习扩展

- **交叉流量**: 模拟共享同一网络路径的其他数据流，用于测试媒体流在竞争条件下的表现。
- **伪 TCP (FakeTcp)**: 模拟 TCP 的拥塞控制行为（Reno 算法），使用消息而非流式传输。

## 设计模式

- **工厂方法模式** — 封装不同交叉流量生成器的创建。
