# metrics_exporter

## 概述

`metrics_exporter` 定义了指标导出器接口 `MetricsExporter`。用于将测试指标导出为特定格式（如 Chrome Performance Dashboard JSON、Protobuf、stdout 文本等）。

## 头文件接口 (.h)

### `MetricsExporter` 抽象接口

- `Export(ArrayView<const Metric> metrics)` — 导出指定指标列表，返回是否成功。

## 设计模式

- **策略模式（导出策略）** — 不同实现导出不同格式（Chrome Dashboard、stdout、Protobuf 文件等）。
