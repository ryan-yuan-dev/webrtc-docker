# h264_profile_level_id

## 概述

`h264_profile_level_id` 实现 H.264 视频编码中 Profile 和 Level 的解析与比较功能。核心任务是处理 SDP 协商中 `profile-level-id` 参数——一个用 6 个十六进制字符（3 字节）表示的编码能力标识。该模块将字节流解析为 `H264ProfileLevelId` 结构体，提供 Profile/Level 的序列化、比较和 Level 适配检测功能。

## 头文件接口 (.h)

**枚举/结构体**：
- `H264Profile`：定义 6 种 Profile（ConstrainedBaseline、Baseline、Main、ConstrainedHigh、High、PredictiveHigh444）。
- `H264Level`：定义 15 种 Level（Level1_b 到 Level5_2），其枚举值等于 Level 编号的 10 倍，Level1_b 为特殊值 0。
- `H264ProfileLevelId`：组合 Profile 和 Level 的简单结构体。

**核心函数**：
- `ParseH264ProfileLevelId(const char*)`：解析 6 字符十六进制字符串为 `H264ProfileLevelId`。
- `ParseSdpForH264ProfileLevelId(CodecParameterMap&)`：从 SDP 参数中提取 `profile-level-id`，缺失时返回默认值（ConstrainedBaseline / Level3.1）。
- `H264ProfileLevelIdToString(H264ProfileLevelId)`：将结构体序列化为 6 字符字符串。
- `H264SupportedLevel(max_pixels, max_fps)`：根据解码器能支持的最大像素数和帧率，返回最高兼容的 Level。
- `H264IsSameProfile` / `H264IsSameProfileAndLevel`：比较两组 SDP 参数的 Profile/Level 兼容性。

## 实现文件 (.cc)

**内部机制**：
- `BitPattern` 类：用于匹配 `profile_idc` / `profile_iop` 字节的位模式。`kProfilePatterns` 表（来自 RFC 6184 Section 8.1）定义了 `profile_idc` 和 `profile_iop` 到 `H264Profile` 的映射关系。例如 `0x42/x1xx0000` 对应 ConstrainedBaseline。
- `kLevelConstraints` 表：来自 ITU-T H.264 Table A-1，定义了每个 Level 的最大宏块数/秒和最大宏块帧大小。
- `ParseH264ProfileLevelId`：将 6 字符十六进制字符串拆分为 `profile_idc`、`profile_iop`、`level_idc` 三个字节。对 Level 11 会检查 Constraint Set 3 标志位以区分 Level 1b 和 Level 1.1。然后遍历 `kProfilePatterns` 查找匹配的 Profile。
- `H264SupportedLevel`：从最高 Level 向下遍历 `kLevelConstraints`，找到满足像素数和帧率约束的 Level。
- `ParseSdpForH264ProfileLevelId`：特别处理 Level 1b 的情况（Profile 与 level_idc 的组合映射到特定的 6 字符编码，如 `42f00b`）。
- 默认 Profile-Level ID：规范默认应为 Baseline/Level1，但为向后兼容选择 ConstrainedBaseline/Level3.1（参见 crbug.com/webrtc/6337）。

## 学习扩展

- H.264 Profile-Level ID 的三字节格式：`(profile_idc)(profile_iop)(level_idc)`，是 H.264 RTP 打包规范 RFC 6184 的一部分。
- H.264 Level 定义了分辨率、帧率和码率的上限。Level 的判定基于宏块（16x16 像素块）数量而非像素数。
- WebRTC 使用 ConstrainedBaseline/Level3.1 作为默认值，确保与绝大多数 H.264 实现兼容。
- `kConstraintSet3Flag`（0x10）用于区分 Level 1b 和 Level 1.1，这是 H.264 规范中特有的边界情况。

## 设计模式

**表驱动模式**：使用 `kProfilePatterns` 和 `kLevelConstraints` 两个静态查找表代替复杂的条件分支逻辑。`BitPattern` 类通过位掩码匹配实现高效的模式识别。这种设计使得添加新的 Profile 或 Level 约束只需扩展表条目即可。

**编译期常量表达式**：`ByteMaskString` 和 `BitPattern` 构造函数均使用 `constexpr`，使得模式匹配表可以在编译期完成初始化，无运行时开销。
