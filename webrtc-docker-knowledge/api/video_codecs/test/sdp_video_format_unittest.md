# sdp_video_format_unittest

## 概述

验证 `SdpVideoFormat::IsSameCodec` 方法的正确性，测试多种编解码器的名称大小写匹配、参数匹配和非匹配场景。

## 测试用例

- `SameCodecNameNoParameters`：验证相同编解码器名称（忽略大小写）匹配。
- `DifferentCodecNameNoParameters`：验证不同编解码器不匹配。
- `SameCodecNameSameParameters`：验证相同编解码器+相同参数匹配，覆盖 VP9 Profile、H264 Profile-Level-ID、AV1 Profile、H265 Profile/Tier/Level。
- `SameCodecNameDifferentParameters`：验证不同 Profile/Level 不匹配，同时验证 AV1 仅比较 Profile 不比较 tier/level（因为它们被视为不对称参数）。
- `DifferentCodecNameSameParameters`：验证即使参数相同但名称不同也不匹配。
- `H264PacketizationMode`：验证 H.264 packetization-mode 的比较逻辑（默认 mode 0 与显式 mode 0 匹配，与 mode 1 不匹配）。
