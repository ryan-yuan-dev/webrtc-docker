# frame_instrumentation_data

## 概述

`FrameInstrumentationData` 是 WebRTC 视频质量检测（Corruption Detection）系统的核心数据单元，描述编码器端为某一帧生成的检测辅助信息。该数据随 RTP 包传输到接收端，用于接收端验证视频流是否存在质量劣化。包含 Halton 序列索引、标准差、亮度/色度错误阈值和采样值数组。

## 头文件接口 (.h)

- **关键字段**（私有）：`sequence_index_`（Halton 序列索引）、`droppable_`（是否可丢弃帧）、`std_dev_`（高斯滤波标准差）、`luma_error_threshold_` / `chroma_error_threshold_`（亮度/色度错误阈值）、`sample_values_`（采样值列表）。
- **Setter 方法**：`SetSequenceIndex()`、`SetStdDev()`、`SetLumaErrorThreshold()`、`SetChromaErrorThreshold()`、`SetSampleValues()`（两个重载：`ArrayView` 或 `vector&&`）。
- **便捷方法**：
  - `holds_upper_bits()`：非 droppable 且 sequence_index 的低 7 位全为 0，表示此帧携带序列索引的高位信息。
  - `is_sync_only()`：无采样值（仅同步消息）。

## 实现文件 (.cc)

- **常量限制**：
  - `kMaxSequenceIndex = (1 << 14) - 1`（14 位最大值）。
  - `kMaxStdDev = 40.0`（标准差最大值）。
  - `kMaxErrorThreshold = 15`（错误阈值最大值）。
- **SetSampleValues**：校验采样值范围 [0.0, 255.0]，通过后拷贝或移动数据。
- **Setter 校验**：所有 setter 方法都有严格的边界检查，非法值返回 false。

## 学习扩展

- **Halton 序列**：低差异序列（Low-discrepancy sequence），用于在图像中均匀采样少量像素点。`sequence_index_` 记录当前 Halton 序列的进度。
- **bits 分割**：sequence_index 的 14 位中的高 7 位（`holds_upper_bits()`）和低 7 位分别在不同 RTP 包中传输，实现增量更新。

## 设计模式

**数据对象模式（Data Object）**：作为 corruption detection 数据在编码器端和接收端之间的传递载体，提供严格的输入校验和便捷的状态查询方法。
