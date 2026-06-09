# metrics_logger

## 概述

`metrics_logger` 模块定义了指标记录器接口 `MetricsLogger` 和默认实现 `DefaultMetricsLogger`。用于在测试中收集性能指标，支持单值指标、时序指标和仅有预计算统计的指标。

## 头文件接口 (.h)

### `MetricsLogger` 抽象接口

| 方法 | 说明 |
|------|------|
| `LogSingleValueMetric(name, test_case, value, unit, direction, metadata)` | 记录单值指标 |
| `LogMetric(name, test_case, values, unit, direction, metadata)` | 记录基于 SamplesStatsCounter 的时序指标 |
| `LogMetric(name, test_case, stats, unit, direction, metadata)` | 记录只含预计算统计的指标 |
| `GetCollectedMetrics()` | 获取所有已收集指标 |

### `DefaultMetricsLogger` 类

实现 `MetricsLogger`，内部使用 `MetricsAccumulator` 和线程安全的 `vector<Metric>`：

- 使用 `Mutex` 保护 `metrics_` 向量。
- 内部持有 `MetricsAccumulator` 实例。
- 使用时钟提供时间戳。

## 实现文件 (.cc)

- `LogSingleValueMetric`: 创建包含单个样本的 `Metric`，同时设置 `stats.mean/min/max` 为单值。
- `LogMetric(values)`: 遍历 `SamplesStatsCounter` 中的所有样本，构建 `TimeSeries`，并调用 `ToStats()` 计算统计。
- `LogMetric(stats)`: 创建仅有统计（无样本）的 `Metric`。
- `GetCollectedMetrics()`: 结合 `MetricsAccumulator` 中的指标和 `metrics_` 中的指标返回。
- `ToStats()`: 从 `SamplesStatsCounter` 提取平均值、标准差、最小/最大值。

## 学习扩展

- **MetricsAccumulator**: 累加器模式，允许不同组件独立贡献指标，最终汇总。

## 设计模式

- **策略模式（记录策略）** — `MetricsLogger` 接口支持多种记录策略。
- **收集器模式** — 收集并集中管理测试指标。
- **线程安全模式** — 使用 `Mutex` 保护共享数据结构。
