# global_metrics_logger_and_exporter

## 概述

提供全局的指标记录器和导出器管理功能。`GetGlobalMetricsLogger()` 返回一个进程全局共享的 `DefaultMetricsLogger` 实例，`ExportPerfMetric()` 将所有记录的指标通过注册的 `MetricsExporter` 列表导出。

## 头文件接口 (.h)

- **`GetGlobalMetricsLogger()`** — 返回全局 `MetricsLogger*` 单例。
- **`ExportPerfMetric(const MetricsLogger&)`** — 通过所有已注册的导出器导出指标。
- **`MetricsLogger::GetMetricsExporter()`** — 获取导出器列表。
- **`MetricsLogger::SetExporters(vector<unique_ptr<MetricsExporter>>)`** — 设置导出器列表。
