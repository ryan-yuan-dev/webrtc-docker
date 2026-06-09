# print_result_proxy_metrics_exporter

## 概述

将测试指标导出为 `print_result` 风格格式，与 Chromium 的 `PrintResult` 兼容。用于将测试结果输出到控制台或其他标准输出。

## 关键接口

- 继承 `MetricsExporter`。
- `Export(metrics)` 将指标打印为标准化的 `print_result` 格式。
