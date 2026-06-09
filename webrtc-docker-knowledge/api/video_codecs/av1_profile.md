# av1_profile

## 概述

`av1_profile` 提供 AV1 视频编码 Profile 的定义和 SDP 参数解析工具。它定义了 WebRTC 支持的 AV1 Profile 枚举（Profile0/1/2），并提供了在 SDP 格式参数与 `AV1Profile` 枚举之间互相转换的辅助函数。该模块是 SDP 协商过程中 AV1 编解码器参数匹配的关键组件。

## 头文件接口 (.h)

**枚举 `AV1Profile`**：定义了三个 AV1 Profile 值，枚举值直接映射到 SDP 中使用的数字编号（0、1、2），遵循 AOMedia AV1 规范 Annex A。

**核心函数**：
- `AV1ProfileToString(AV1Profile)`：将 Profile 枚举转换为字符串，未知值返回 `"0"`。
- `StringToAV1Profile(string_view)`：将字符串解析为 `AV1Profile`，无效字符串返回 `nullopt`。
- `ParseSdpForAV1Profile(CodecParameterMap&)`：从 SDP 的 key-value 参数映射中提取 AV1 Profile；未指定时默认返回 `kProfile0`；指定了无效值时返回空。
- `AV1IsSameProfile(params1, params2)`：比较两组 SDP 参数是否指定了相同的 AV1 Profile。

## 实现文件 (.cc)

**内部机制**：
- `AV1ProfileToString`：通过 `switch` 将枚举映射为 `"0"`, `"1"`, `"2"` 字符串。
- `StringToAV1Profile`：使用 `StringToNumber<int>` 将字符串转为整数后匹配枚举值。
- `ParseSdpForAV1Profile`：在 `CodecParameterMap` 中查找键 `kAv1FmtpProfile`（定义在 `media_constants.h` 中），不存在时返回 `kProfile0`。
- `AV1IsSameProfile`：分别解析两个参数映射的 Profile，要求都存在且相等。

## 学习扩展

- AV1 Profile 决定了色度子采样格式和位深度的支持能力：Profile0 支持 4:0:0 和 4:2:0 8-bit；Profile1 增加 4:4:4 8-bit；Profile2 支持 4:2:2 10-bit 和 4:4:4 10+bit。
- SDP 中的 `profile` 字段定义在 `a=fmtp` 行中，是 AV1 RTP 规范（draft-ietf-avtcore-av1-rtp）的一部分。
- `AV1IsSameProfile` 在编解码能力协商中用于判断两个 SdpVideoFormat 是否属于同一编解码器"家族"。

## 设计模式

**策略模式**：Profile 解析策略集中于此模块，供 SDP 协商和编解码器匹配等上层模块调用。各 Profile 处理函数职责单一，通过 switch 枚举分支完成映射，便于扩展新 Profile。
