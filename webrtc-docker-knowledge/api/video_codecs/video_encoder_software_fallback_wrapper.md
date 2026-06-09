# video_encoder_software_fallback_wrapper

## 概述

`VideoEncoderSoftwareFallbackWrapper` 是视频编码器的软件回退包装器。与解码器版本类似，它在硬件编码器无法工作时自动回退到软件编码。但编码器版本的逻辑更为复杂，额外支持"基于分辨率的强制回退"和"基于时间层支持的强制回退"两种策略，允许通过 Field Trial 配置精细化控制。

## 头文件接口 (.h)

**工厂函数**：
- `CreateVideoEncoderSoftwareFallbackWrapper(env, sw_fallback_encoder, hw_encoder, prefer_temporal_support)`：创建编码器回退包装器。`prefer_temporal_support` 表示当软件编码器支持时间层而硬件编码器不支持时，应强制使用软件编码器。

## 实现文件 (.cc)

**`ForcedFallbackParams`**：回退参数结构体，支持两种触发模式：
- `resolution_based_switch`：当分辨率 <= `max_pixels`（默认 320x240）时强制回退。
- `temporal_based_switch`：当需要多层时间层（`NumberOfTemporalLayers(codec, 0) != 1`）时，在软件编码器支持时间层而硬件不支持时触发回退。

**Field Trial 配置**：
1. `WebRTC-Video-EncoderFallbackSettings`：简化版配置，仅指定 `resolution_threshold_px`。
2. `WebRTC-VP8-Forced-Fallback-Encoder-v2`：VP8 专用的详细配置，格式为 `Enabled-{min_pixels},{max_pixels},{min_bps}`。

**核心类 `VideoEncoderSoftwareFallbackWrapper`**：

**状态管理**：
- `kUninitialized`：未初始化。
- `kMainEncoderUsed`：正在使用主（硬件）编码器。
- `kFallbackDueToFailure`：因失败回退到软件。
- `kForcedFallback`：因配置强制回退。

**初始化流程**：
1. 检查是否应使用强制回退（`TryInitForcedFallbackEncoder`）。
2. 如果是，尝试初始化软件编码器。
3. 否则，尝试初始化硬件编码器。
4. 硬件初始化失败且非 Simulcast 参数错误时，尝试软件初始化。

**回退触发机制**：
- `EncodeWithMainEncoder` 检测到 `WEBRTC_VIDEO_CODEC_FALLBACK_SOFTWARE` 返回码时触发回退。
- 回退时处理缓冲区格式转换：如果 Fallback 编码器不支持 Native Handle，将帧转换为 I420 格式。

**`PrimeEncoder`**：回退后重放所有先前设置的参数（回调、码率、RTT、丢包率、丢包通知），确保新编码器状态与旧编码器一致。

**`GetEncoderInfo`**：返回各编码器信息后合并处理：
- `requested_resolution_alignment` 取两者的 LCM（最小公倍数）。
- `apply_alignment_to_all_simulcast_layers` 取 OR。
- 若为 VP8 分辨率回退，调整 `min_pixels_per_frame`。

## 学习扩展

- 编码器回退比解码器回退更复杂，因为编码器涉及更多的运行状态和参数（码率、帧率、丢包率等），回退时需要完整的状态迁移。
- Field Trial 的设计允许在不修改代码的情况下调整回退策略，适合线上实验和调优。
- LCM 对齐处理确保编码器切换时不会因为分辨率对齐要求不同而产生不兼容。
- 当软件编码器不支持 Native Handle 时，包装器负责将 HW 纹理帧转换为 I420 软件帧，这是编码器回退的关键兼容层。

## 设计模式

**装饰器模式（Decorator）**：与解码器版本一样，`VideoEncoderSoftwareFallbackWrapper` 实现了 `VideoEncoder` 接口，透明地添加了回退功能。

**状态模式（State）**：使用 `EncoderState` 枚举跟踪四种状态，状态转换图：`kUninitialized -> kMainEncoderUsed -> kFallbackDueToFailure` 或 `kUninitialized -> kForcedFallback`。`current_encoder()` 根据状态返回对应的编码器实例。

**中介者**：`PrimeEncoder` 方法负责在回退时协调所有待传递的状态（回调、码率、网络条件等），是回退流程中的关键编排逻辑。
