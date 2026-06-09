# metrics_accumulator

## 概述

`MetricsAccumulator` 提供一个累加器，允许不同组件独立地向同一个指标贡献数据点。它维护每个指标的时间序列，记录样本的时间戳、值和元数据，适用于需要从多个来源收集同名指标的测试场景。

## 头文件接口 (.h)

### `MetricsAccumulator` 类

- **`AddSample(name, test_case, timestamp, value, unit, direction, sample_metadata, metric_metadata)`** — 向指定指标添加样本点。如果指标不存在则创建。
- **`GetCollectedMetrics()`** — 返回所有已收集指标的列表。

## 学习扩展

- 与 `DefaultMetricsLogger` 配合使用，`DefaultMetricsLogger` 内部持有一个 `MetricsAccumulator` 实例。

## 设计模式

- **累加器模式** — 允许多个来源合并到同一指标。
