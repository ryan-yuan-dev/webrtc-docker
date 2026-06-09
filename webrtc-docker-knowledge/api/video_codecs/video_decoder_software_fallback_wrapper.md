# video_decoder_software_fallback_wrapper

## 概述

`VideoDecoderSoftwareFallbackWrapper` 是一个用于装饰视频解码器的包装器，提供"硬件解码失败时自动回退到软件解码"的容错机制。当硬件解码器因限制（如分辨率超出硬件能力）而无法解码时，自动切换到软件解码器，保证视频流不中断。该包装器对上层应用透明。

## 头文件接口 (.h)

**工厂函数**：
- `CreateVideoDecoderSoftwareFallbackWrapper(env, sw_fallback_decoder, hw_decoder)`：创建软件回退包装器。接收一个软件解码器和一个硬件解码器作为参数。

## 实现文件 (.cc)

**核心类 `VideoDecoderSoftwareFallbackWrapper`**：

**状态管理**：
- `DecoderType::kNone`：未初始化。
- `DecoderType::kHardware`：当前使用硬件解码器。
- `DecoderType::kFallback`：已回退到软件解码器。

**回退触发条件**：
- `force_sw_decoder_fallback_`：通过 Field Trial `WebRTC-Video-ForcedSwDecoderFallback` 强制回退。
- 硬件解码器 `Decode` 返回 `WEBRTC_VIDEO_CODEC_FALLBACK_SOFTWARE`。
- 硬件解码器连续 `kMaxConsequtiveHwErrors`（4）次返回错误（仅统计关键帧上的错误）。

**回退逻辑**：
1. `Configure`：优先初始化硬件解码器，失败时回退到软件。
2. `Decode`：硬件解码时检测回退条件；回退后所有帧转由软件解码器处理。
3. `InitFallbackDecoder`：初始化软件解码器，记录硬件解码帧数到 UMA 直方图（用于监控）。
4. `Release`：释放当前活动的解码器，重置状态为 `kNone`。

**解码器信息**：
- `GetDecoderInfo()` / `ImplementationName()`：回退状态时返回 `"软件解码器名 (fallback from: 硬件解码器名)"` 格式的标识。

## 学习扩展

- 连续错误计数仅统计关键帧错误，因为关键帧的解码失败后可以通过请求新的关键帧来恢复，而非关键帧的错误可能是暂时的。
- UMA 直方图 `WebRTC.Video.HardwareDecodedFramesBetweenSoftwareFallbacks.*` 按编解码器类型分类记录硬件解码帧数，帮助分析不同编解码器的硬件解码稳定性。
- 回退转换是单向的：一旦回退到软件解码，不会自动切回硬件解码。

## 设计模式

**装饰器模式（Decorator）**：包装器实现了与原始对象相同的 `VideoDecoder` 接口，在保持接口一致性的前提下增加了"失败回退"功能。对调用者完全透明。

**状态模式（State）**：使用 `decoder_type_` 枚举跟踪当前活动解码器的状态，根据状态决定将调用委托给硬件还是软件解码器。状态转换图：`kNone -> kHardware -> kFallback`。
