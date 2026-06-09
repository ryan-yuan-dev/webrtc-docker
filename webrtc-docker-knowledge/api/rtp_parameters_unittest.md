# rtp_parameters_unittest

## 概述

`rtp_parameters_unittest.cc` 是对 `api/rtp_parameters.h` 中 RTP 参数结构体的单元测试文件。

## 测试范围

- `RtpCodec` 的 `IsResiliencyCodec()` / `IsMediaCodec()` 判断
- `RtpCodec::mime_type()` 格式
- `RtpEncodingParameters` 默认值和相等比较
- `RtpCodecParameters` 默认值和相等比较
- `RtpCapabilities` 默认值和相等比较
- `RtcpParameters` 默认值和相等比较
- `RtpParameters` 默认值和相等比较
- `RtpExtension::IsSupportedForAudio()` / `IsSupportedForVideo()` 支持列表
- `RtpExtension::IsEncryptionSupported()` 加密支持
- `RtpExtension::FindHeaderExtensionByUri()` 查找逻辑
- `RtpExtension::FindHeaderExtensionByUriAndEncryption()` 查找逻辑
- `RtpExtension::DeduplicateHeaderExtensions()` 去重逻辑
- `RtpHeaderExtensionCapability` 各种构造函数
- `DegradationPreferenceToString()` 字符串转换
