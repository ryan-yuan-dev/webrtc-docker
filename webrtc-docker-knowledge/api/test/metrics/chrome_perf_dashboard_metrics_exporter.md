# chrome_perf_dashboard_metrics_exporter

## 概述

将测试指标导出为 Chrome Performance Dashboard JSON 格式。生成的 JSON 文件可以被 Chrome Performance Dashboard 服务消费和展示。

## 关键接口

- 继承 `MetricsExporter`。
- `Export(metrics)` 将指标序列化为 Chrome Dashboard 兼容的 JSON 格式。
