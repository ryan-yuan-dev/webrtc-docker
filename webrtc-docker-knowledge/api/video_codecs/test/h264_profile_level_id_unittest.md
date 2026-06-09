# h264_profile_level_id_unittest

## 概述

全面测试 H.264 Profile-Level ID 的解析、序列化和 Level 适配功能，覆盖边界情况和规范合规性。

## 测试用例

- `TestParsingInvalid`：验证无效字符串返回 `nullopt`（空字符串、包含空格、长度错误、非 hex 字符、无效的 Level/Profile）。
- `TestParsingLevel`：验证 Level 解析结果（31/11/1b/42/52）。
- `TestParsingConstrainedBaseline/Baseline/Main/High/ConstrainedHigh`：验证各 Profile 的正确识别。
- `TestSupportedLevel`：验证分辨率+帧率到 Level 的映射（640x480@25fps -> Level 2.1、720p@30fps -> Level 3.1 等）。
- `TestSupportedLevelInvalid`：验证无法达到最小 Level 要求时返回空。
- `TestToString`：验证 `H264ProfileLevelIdToString` 的序列化结果。
- `TestToStringLevel1b`：验证 Level 1b 的特殊序列化逻辑。
- `TestToStringRoundTrip`：验证解析 -> 序列化的往返一致性（包括大小写）。
- `TestToStringInvalid`：验证非法组合（如 High + Level 1b、未知 Profile）返回空。
- `TestParseSdpProfileLevelIdEmpty/ConstrainedHigh/Invalid`：验证 SDP 参数解析的各种情况。
