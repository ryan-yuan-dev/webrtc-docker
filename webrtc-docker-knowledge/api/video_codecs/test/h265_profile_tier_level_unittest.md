# h265_profile_tier_level_unittest

## 概述

全面测试 H.265 Profile、Tier、Level 的字符串序列化/反序列化、SDP 参数解析和兼容性比较功能。

## 测试用例

- `TestLevelToString` / `TestProfileToString` / `TestTierToString`：验证枚举到字符串的映射。
- `TestStringToProfile` / `TestStringToLevel` / `TestStringToTier`：验证字符串到枚举的解析，包括有效值和无效值的边界情况。
- `TestParseSdpProfileTierLevelAllEmpty`：验证 SDP 参数全部缺失时的默认值。
- `TestParseSdpProfileTierLevelPartialEmpty`：验证部分参数缺失时的默认值应用。
- `TestParseSdpProfileTierLevelInvalid`：验证无效组合（如 Level 3.1 + Tier1）返回空。
- `TestToStringRoundTrip`：验证字符串-枚举-字符串往返一致性。
- `TestProfileTierLevelCompare` / `TestProfileCompare` / `TestTierCompare`：验证三种比较函数的正确性。
- `TestGetSupportedH265Level`：验证不同分辨率和帧率下支持的 Level 计算结果，覆盖 64x64、720p、1080p、4K、8K 和超宽分辨率。
