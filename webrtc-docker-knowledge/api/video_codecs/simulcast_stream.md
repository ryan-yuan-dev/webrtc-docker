# simulcast_stream

## 概述

`SimulcastStream` 定义 Simulcast（同时发送多流）场景下单个流的配置参数。该结构体描述了一个 Simulcast 流的分辨率、帧率、码率和激活状态等信息。它是 `VideoCodec` 类中 `simulcastStream` 数组的成员类型。此外，`SpatialLayer` 类型是 `SimulcastStream` 的别名，用于 SVC 空间层场景。

## 头文件接口 (.h)

**结构体 `SimulcastStream`**：
- `width` / `height`：流的分辨率。
- `maxFramerate`：最大帧率。
- `numberOfTemporalLayers`：时间层数（1-3）。
- `maxBitrate` / `targetBitrate` / `minBitrate`：码率限制（kbps）。
- `qpMax`：最高 QP（最低质量限制）。
- `active`：是否活动（编码并发送）。
- `format`：可选 `SdpVideoFormat`，用于混合编码器 Simulcast 场景。

**成员函数**：
- `GetNumberOfTemporalLayers()`：获取时间层数。
- `SetNumberOfTemporalLayers(n)`：设置时间层数（范围 1-3）。
- `GetScalabilityMode()`：将时间层数转换为对应的 `ScalabilityMode`（L1T1/L1T2/L1T3）。
- `operator==` / `operator!=`：比较两个流配置是否相等。

## 实现文件 (.cc)

- `SetNumberOfTemporalLayers` 使用 `RTC_DCHECK` 确保值在 1 到 3 之间。
- `GetScalabilityMode` 将 1/2/3 时间层映射为 `kL1T1` / `kL1T2` / `kL1T3`。
- `operator==` 比较所有字段值是否相等。

## 学习扩展

- Simulcast 流与 SVC 空间层的区别：Simulcast 流是完全独立的编码器实例输出的独立码流，而 SVC 空间层在同一编码器内有关联预测。
- `format` 字段用于混合编码器 Simulcast——每个 Simulcast 流可以使用不同的编解码器。
- 该结构体未来将与 `VideoStream`（`VideoEncoderConfig` 的一部分）合并（参见 bugs.webrtc.org/6883）。

## 设计模式

**数据传输对象（DTO）**：`SimulcastStream` 是纯粹的数据结构，封装流的配置信息并在各模块间传递。其方法主要是对字段的访问和校验，不包含复杂的业务逻辑。
