# sdp_video_format

## 概述

`SdpVideoFormat` 是 WebRTC 中表示单个视频编解码器 SDP 格式的核心结构体。它封装了编解码器的名称、关键参数（`CodecParameterMap`）和可伸缩性模式列表。该结构体是编解码器能力协商的基础单元——编码器工厂通过它描述支持的格式，PeerConnection 通过它匹配发送端和接收端的编解码能力。

## 头文件接口 (.h)

**结构体 `SdpVideoFormat`**：
- `name`：编解码器名称（如 `"VP8"`, `"H264"`, `"AV1"`）。
- `parameters`：`CodecParameterMap`（即 `std::map<string, string>`），包含 FMTP 参数。
- `scalability_modes`：该格式支持的可伸缩性模式列表。

**成员函数**：
- `IsSameCodec(other)`：判断两个格式是否表示同一编解码器（名称忽略大小写 + 编解码器特定参数匹配）。
- `IsCodecInList(formats)`：检查当前格式是否在给定的格式列表中能找到匹配项。
- `ToString()`：格式化为可读字符串。

**工厂静态方法**：为常用编解码器提供预设格式：
- `VP8()`：返回默认 VP8 格式。
- `H264()` / `H265()`：返回基础 H.264/H.265 格式。
- `VP9Profile0()` ~ `VP9Profile3()`：为 VP9 不同 Profile 设置 `profile-id` 参数。
- `AV1Profile0()` / `AV1Profile1()`：为 AV1 设置 `profile`、`level-idx` 和 `tier` 参数。

**辅助函数**：
- `FuzzyMatchSdpVideoFormat(supported_formats, format)`：当严格精确匹配失败时，使用模糊匹配找最佳匹配格式（基于参数匹配数）。

## 实现文件 (.cc)

**`IsSameCodecSpecific`**：核心的比较逻辑，根据编解码器类型使用不同的 Profile 比较函数：
- H264：比较 Profile + Packetization Mode。
- VP9：比较 Profile。
- AV1：比较 Profile（向后兼容）。
- H265：比较 Profile + Tier + TxMode。
- 其他编解码器：名称匹配即视为相同。

**H.264 特定处理**：
- `H264GetPacketizationModeOrDefault`：获取 `packetization-mode`，默认 `"0"`（RFC 6184 Section 6.2）。
- `H264IsSamePacketizationMode`：比较两个格式的 packetization-mode 是否相同。

**H.265 特定处理**：
- `GetH265TxModeOrDefault`：获取 H.265 的 `tx-mode`，默认 `"SRST"`（RFC 7798 Section 7.1）。
- `IsSameH265TxMode`：比较时忽略大小写。

**模糊匹配**：`FuzzyMatchSdpVideoFormat` 遍历支持的格式，对名称相同的格式计算匹配的参数数量，选择参数匹配最多的格式。这在 SDP Offer/Answer 模型中参数不完全一致时很有用。

## 学习扩展

- `SdpVideoFormat` 的 `IsSameCodec` 与 `operator==` 是不同的：前者是语义上的"同一编解码器"（仅检查对兼容性关键的参数），后者是字段级别的严格全等比较。
- `CodecParameterMap`（原名 `Parameters`）是 SDP FMTP（Format Parameters）的 C++ 表示，每对 key-value 对应 `a=fmtp` 行中的一个参数。
- WebRTC 目前正在从 `SdpVideoFormat` + 传统 `VideoEncoder`/`VideoDecoder` 接口向新的 `VideoEncoderInterface`/`VideoDecoderInterface` 过渡。

## 设计模式

**值对象（Value Object）**：`SdpVideoFormat` 是不可变的值类型，通过值传递和拷贝（拷贝构造函数和 operator= 都是 default 的）。

**工厂方法**：静态工厂方法（`VP8()`、`H264()` 等）提供常用预设格式的便捷创建方式。

**策略模式**：`IsSameCodecSpecific` 根据编解码器类型选择不同的参数比较策略，将编解码器特有的匹配逻辑封装在独立的比较函数中。
