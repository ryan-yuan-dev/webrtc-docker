# h265_profile_tier_level

## 概述

`h265_profile_tier_level` 实现 H.265/HEVC 视频编码 Profile、Tier 和 Level 的解析与比较功能。H.265 比 H.264 增加了 Tier（层级）维度——Tier 表示编码器能够处理的最大比特率水平（Main Tier 或 High Tier）。该模块负责从 SDP 参数中提取 `profile-id`、`tier-flag`、`level-id` 字段，并提供序列化和匹配检测。

## 头文件接口 (.h)

**枚举/结构体**：
- `H265Profile`：定义 11 种 Profile（Main、Main10、MainStill 等），枚举值直接对应 SDP 中使用的数字。
- `H265Tier`：定义 Tier0（Main Tier）和 Tier1（High Tier）。
- `H265Level`：定义 13 种 Level（Level1 到 Level6.2），枚举值等于 Level 编号的 30 倍。
- `H265ProfileTierLevel`：组合 Profile、Tier、Level 的结构体。

**核心函数**：
- `H265ProfileToString` / `H265TierToString` / `H265LevelToString`：将枚举转换为字符串。
- `StringToH265Profile` / `StringToH265Tier` / `StringToH265Level`：将字符串解析为枚举。
- `ParseSdpForH265ProfileTierLevel(CodecParameterMap&)`：从 SDP 参数中提取 profile/tier/level，缺失时使用默认值（Main/ Tier0 / Level3.1）。
- `GetSupportedH265Level(Resolution, max_fps)`：根据分辨率和帧率计算支持的 Level。
- `H265IsSameProfileTierLevel` / `H265IsSameProfile` / `H265IsSameTier`：比较 SDP 参数的兼容性。

## 实现文件 (.cc)

**内部机制**：
- 定义三个 FMTP 参数名称常量：`profile-id`、`tier-flag`、`level-id`。
- `kLevelConstraints` 表来自 ITU-T H.265 (09/2023) Table A.8、A.9、A.11，定义每个 Level 的最大亮度像素数、最大亮度采样率和最大宽/高像素数。
- 使用 `kMinCbSizeYMax = 64` 对齐宽高值，以计算亮图像尺寸的上界。
- `ParseSdpForH265ProfileTierLevel`：分别从参数映射中查找三项，缺失时全部使用默认值。特殊校验：Level <= 3.1 不允许 High Tier（Tier1）。
- `GetSupportedH265Level`：从最高 Level 向下遍历，检查亮度像素数和采样率约束。与 H.264 不同，H.265 还检查了 `max_pic_width_or_height_in_pixels`。
- 宽高对齐：`(val + 63) & ~63` 确保对齐到 64 的倍数，这是 H.265 CTU（Coding Tree Unit）大小的保守对齐方式。

## 学习扩展

- H.265 引入了 Tier 概念：Main Tier 针对大多数应用，High Tier 针对更高比特率需求的专业应用。
- H.265 Level 使用亮度像素数（Luma Picture Size）而非 H.264 的宏块数作为约束基准，反映其可变的 CTU 大小。
- `max_pic_width_or_height_in_pixels` 是根据 H.265 Section A.4.1 推算的，确保宽高值是 MinCbSizeY(8) 的倍数且不超过 `sqrt(max_luma_picture_size * 8)`。
- 枚举值为 30 倍的 Level 编号（如 Level 1 = 30, Level 2 = 60），而非 H.264 的 10 倍，这是因为 H.265 Level 定义更细粒度。

## 设计模式

**表驱动模式**：使用 `kLevelConstraints` 静态表管理 Level 约束，新增 Level 只需添加表条目。所有枚举转换函数使用 switch 语句实现双向映射。SDP 解析函数采用"先查找后校验"的模式：分别提取三个参数并校验合法性，最后做组合校验（Tier + Level 约束），这种方式隔离了各参数的解析逻辑，提高可维护性。
