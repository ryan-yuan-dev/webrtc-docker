# stdout_metrics_exporter

## 概述

将测试指标导出到标准输出（stdout），以人类可读的文本格式展示。用于测试执行的即时反馈和简单结果查看。

## 关键接口

- 继承 `MetricsExporter`。
- `Export(metrics)` 将指标格式化为文本输出到 stdout。
