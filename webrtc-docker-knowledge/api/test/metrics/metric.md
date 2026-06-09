# metric

## 概述

`metric` 模块定义了测试指标（Metric）的核心数据结构，包括 `Metric` 结构体、`Unit` 枚举和 `ImprovementDirection` 枚举。用于表示测试过程中收集的性能指标（如 PSNR、SSIM、解码时间等）及其统计信息。

## 头文件接口 (.h)

### `Unit` 枚举

| 值 | 说明 |
|------|------|
| `kMilliseconds` | 毫秒 |
| `kPercent` | 百分比 |
| `kBytes` | 字节 |
| `kKilobitsPerSecond` | 千比特每秒 |
| `kHertz` | 赫兹 |
| `kUnitless` | 无量纲（比率或未列出的单位） |
| `kCount` | 计数 |

### `ImprovementDirection` 枚举

| 值 | 说明 |
|------|------|
| `kBiggerIsBetter` | 值越大越好（如 PSNR） |
| `kNeitherIsBetter` | 无方向性 |
| `kSmallerIsBetter` | 值越小越好（如延迟） |

### `Metric` 结构体

**`TimeSeries`** — 时序数据：
- `Sample` — 包含 `timestamp`（微秒时间戳）、`value`、`sample_metadata`。
- `samples` — 所有样本的向量。

**`Stats`** — 预计算统计：
- `mean` / `stddev` / `min` / `max` — 均值、标准差、最小、最大值（均为 optional）。

**Metric 字段**：
- `name` — 指标名称（如 PSNR, SSIM）
- `unit` — 单位
- `improvement_direction` — 改进方向
- `test_case` — 测试用例名称
- `metric_metadata` — 指标级别元数据
- `time_series` — 时序样本
- `stats` — 预计算统计

## 实现文件 (.cc)

- `ToString(Unit)` — 将 Unit 枚举转为字符串。
- `ToString(ImprovementDirection)` — 将改进方向枚举转为字符串。

## 设计模式

- **DTO（数据传输对象）** — `Metric` 结构体承载完整指标数据，可在不同模块间传递。
