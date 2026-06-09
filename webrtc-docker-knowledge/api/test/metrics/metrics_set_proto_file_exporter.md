# metrics_set_proto_file_exporter

## 概述

将测试指标导出为 Protobuf 格式的文件。生成的 `.pb` 文件可以用于后续分析和处理。

## 关键接口

- 继承 `MetricsExporter`。
- `Export(metrics)` 将指标编码为 protobuf 格式并写入文件。
