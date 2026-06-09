# vp9_profile

## 概述

`vp9_profile` 提供 VP9 视频编码 Profile 的定义和 SDP 参数解析工具。它定义了 WebRTC 支持的 VP9 Profile 枚举（Profile0/1/2/3），并提供了在 SDP 格式参数与 `VP9Profile` 枚举之间互相转换的辅助函数。

## 头文件接口 (.h)

**常量**：
- `kVP9FmtpProfileId`：FMTP 参数名称 `"profile-id"`。

**枚举 `VP9Profile`**：
- `kProfile0` / `kProfile1` / `kProfile2` / `kProfile3`：四个 VP9 Profile。

**核心函数**：
- `VP9ProfileToString(profile)`：Profile 枚举转字符串。默认返回 `"0"`。
- `StringToVP9Profile(str)`：字符串转枚举。无效字符串返回 `nullopt`。
- `ParseSdpForVP9Profile(params)`：从 SDP 参数映射中提取 VP9 Profile，缺失时默认返回 `kProfile0`。
- `VP9IsSameProfile(params1, params2)`：比较两组 SDP 参数是否指定了相同的 VP9 Profile。

## 实现文件 (.cc)

- `VP9ProfileToString`：将枚举映射为 `"0"`, `"1"`, `"2"`, `"3"` 字符串。
- `StringToVP9Profile`：使用 `StringToNumber<int>` 转换字符串后匹配枚举值。
- `ParseSdpForVP9Profile`：在参数映射中查找键 `kVP9FmtpProfileId`（`"profile-id"`）。
- `VP9IsSameProfile`：分别解析两个参数映射，要求都存在且相等。

## 学习扩展

- VP9 Profile 特性：Profile0 支持 4:2:0 8-bit；Profile1 支持 4:2:0 8-bit + 4:2:2 10-bit；Profile2 支持 4:2:0/4:2:2/4:4:4 10+bit 和 4:2:2 12-bit；Profile3 支持 4:2:0/4:2:2/4:4:4 10+bit 和 4:2:0/4:2:2/4:4:4 12-bit。
- 在 SDP 协商中，`profile-id` 作为 FMTP 参数出现在 `a=fmtp` 行中。
- WebRTC 一般默认使用 VP9 Profile0，Chromium 的 VP9 硬件解码器通常支持 Profile0-2。

## 设计模式

**策略模式**：与 av1_profile、h264_profile_level_id 等 Profile 解析模块采用统一的接口设计风格。每个编解码器的 Profile 解析逻辑封装在独立的函数中，通过 CodecParameterMap 进行输入输出，便于在 SDP 协商流程中统一调用。
