# samples_stats_counter

## 概述

`SamplesStatsCounter` 是一个样本统计计数器，在 `RunningStatistics` 的基础上扩展了百分位数计算（`GetPercentile`）功能。它用于收集数值样本，并提供最小值、最大值、总和、平均值、方差、标准差和百分位数等统计指标。每个样本还带有时间戳和可选的元数据。

## 头文件接口 (.h)

### `SamplesStatsCounter` 类

**内部结构：`StatsSample`**

| 字段 | 类型 | 说明 |
|------|------|------|
| `value` | double | 样本值 |
| `time` | Timestamp | 样本时间戳 |
| `metadata` | map<string,string> | 样本元数据 |

**核心方法：**

| 方法 | 时间复杂度 | 说明 |
|------|-----------|------|
| `AddSample(double)` | 摊销 O(1) | 已废弃，推荐使用带 `StatsSample` 的版本 |
| `AddSample(StatsSample)` | 摊销 O(1) | 添加带时间和元数据的样本 |
| `AddSamples(SamplesStatsCounter)` | O(n) | 合并另一个计数器的所有样本 |
| `IsEmpty()` | O(1) | 检查是否有样本 |
| `NumSamples()` | O(1) | 返回样本数 |
| `GetMin()` | O(1) | 最小值 |
| `GetMax()` | O(1) | 最大值 |
| `GetSum()` | O(1) | 总和 |
| `GetAverage()` | O(1) | 平均值 |
| `GetVariance()` | O(1) | 方差 |
| `GetStandardDeviation()` | O(1) | 标准差 |
| `GetPercentile(double)` | O(n log n) 首调用，后 O(1) | 百分位数，范围 [0, 1] |
| `GetTimedSamples()` | O(1) | 返回所有样本的 ArrayView |
| `GetSamples()` | O(n) | 返回所有样本值的 vector |

**运算符重载：**

- `operator*(counter, double)` / `operator*(double, counter)` — 将所有样本值乘以指定系数，返回新计数器。
- `operator/(counter, double)` — 将所有样本值除以指定系数，返回新计数器。

## 实现文件 (.cc)

### 关键实现逻辑

**`AddSample()`**: 将样本同时存入 `RunningStatistics`（用于 O(1) 的基础统计）和 `samples_` 向量（用于百分位数计算），并标记 `sorted_ = false`。

**`GetPercentile()`**:
1. 检查是否已排序，未排序时对 `samples_` 按值升序排序。
2. 计算原始排名 `raw_rank = percentile * (n-1)`。
3. 分离整数部分和小数部分。
4. 在线性插值公式 `low + fract * (high - low)` 计算最终值。

**`operator*` 和 `operator/`**: 遍历所有样本值进行运算，生成新的 `SamplesStatsCounter` 实例，`const` 保证不对原始计数器造成影响。

### 单元测试 (`samples_stats_counter_unittest.cc`)

| 测试 | 说明 |
|------|------|
| `FullSimpleTest` | 1~100 数据的完整统计验证（min/max/sum/average/百分位数） |
| `VarianceAndDeviation` | 方差的独立计算 |
| `FractionPercentile` | 中位数（0.5 百分位）验证 |
| `TestBorderValues` | 边界百分位（0.01 和 1.0）验证 |
| `VarianceFromUniformDistribution` | 100 万样本的均匀分布方差收敛到 1/12 |
| `NumericStabilityForVariance` | 大数值偏移后的方差数值稳定性 |
| `AddSamples` | 参数化测试，验证不同拆分方式的合并结果一致性 |
| `MultiplyRight` / `MultiplyLeft` | 乘法运算符验证，确认原计数器不被修改 |
| `Divide` | 除法运算符验证 |

## 学习扩展

- **RunningStatistics**: WebRTC 实现的在线统计计算器，使用 Welford 在线算法计算均值和方差，无需存储所有样本。
- **百分位数的线性插值**: 当原始排名不是整数时，使用线性插值在两个相邻样本之间估计百分位数。这是 `Type 7` 百分位数估计方法（R 语言默认，Hyndman & Fan 类型）。
- **Q14 和定点数**: WebRTC 中比率常用 Q14 格式表示。

## 设计模式

- **装饰器模式** — `SamplesStatsCounter` 装饰了 `RunningStatistics`，在其基础上增加百分位数计算功能。
- **值对象模式** — 统计结果为简单的 double 值，支持运算符重载生成变换后的统计。
- **惰性排序** — `sorted_` 标记在添加样本时置 false，在首次调用百分位数时排序，后续 O(1) 访问。
