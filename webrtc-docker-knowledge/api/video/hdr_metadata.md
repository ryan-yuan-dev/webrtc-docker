# hdr_metadata

## 概述

`HdrMetadata` 和 `HdrMasteringMetadata` 是 WebRTC 中表示 HDR（高动态范围）视频元数据的结构体。`HdrMasteringMetadata` 符合 SMPTE ST 2086 规范，描述了母版显示器的色度和亮度特性；`HdrMetadata` 则整合了母版元数据和内容亮度级别信息（MaxCLL、MaxFALL），适用于 HDR10 和 WebM/VP9 格式的 HDR 视频。

## 头文件接口 (.h)

- **`HdrMasteringMetadata`**：
  - 内嵌结构体 `Chromaticity`：表示 xy 色度坐标，范围 [0.0, 1.0]，提供 `Validate()` 校验。
  - 字段：`primary_r`、`primary_g`、`primary_b`（RGB 主原色）、`white_point`（白点）、`luminance_max`（最大亮度，单位 cd/m2，范围 0-20000）、`luminance_min`（最小亮度，范围 0-5）。
  - `Validate()` 校验所有字段合法范围。
- **`HdrMetadata`**：
  - 字段：`mastering_metadata`（母版元数据）、`max_content_light_level`（MaxCLL，最大内容亮度，范围 0-20000 nits）、`max_frame_average_light_level`（MaxFALL，最大帧平均亮度，范围 0-20000 nits）。
  - `Validate()` 校验所有字段。

## 实现文件 (.cc)

- 默认构造函数均为 `= default`，`Chromaticity` 的 x/y 默认初始化为 0.0f。

## 学习扩展

- **SMPTE ST 2086**：母版显示器元数据标准，定义了 mastering display 的色域和亮度范围，用于色调映射（Tone Mapping）参考。
- **MaxCLL / MaxFALL**：CTTS（Content Light Level Information）中的关键参数，分别表示峰值亮度和平均亮度最大值，接收端据此进行动态范围映射。
- **HDR10**：基于 PQ（Perceptual Quantizer，SMPTE ST 2084）传输曲线，使用 `HdrMasteringMetadata` 和 `MaxCLL`/`MaxFALL` 作为静态元数据。
- **HLG**：另一种 HDR 标准，兼容 SDR 显示设备，不需要此类母版元数据。

## 设计模式

**普通数据类（Plain Data Class）**：`HdrMetadata` 和 `HdrMasteringMetadata` 是纯粹的 POD 风格结构体，提供 `Validate()` 校验和 `operator==` 比较，不包含复杂业务逻辑。
