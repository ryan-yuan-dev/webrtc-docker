# video_encoder

## 概述

`VideoEncoder` 是 WebRTC 中视频编码器的核心抽象接口。它定义了所有编码器实现的契约，包括初始化、编码、码率控制、网络条件反馈和元信息查询。接口中还嵌套定义了多个辅助结构体用于编码器信息描述——这些信息被上层的 `VideoStreamEncoder` 用于 CPU 和带宽适应决策。

## 头文件接口 (.h)

**类 `EncodedImageCallback`**：
- `OnEncodedImage(encoded_image, codec_specific_info)`：编码完成回调。
- `OnDroppedFrame(reason)`：帧被丢弃时的回调。

**嵌套结构体/类**：
- `QpThresholds`：QP 阈值区间（low/high），用于质量缩放判断。
- `ScalingSettings`：编码器自适应分辨率缩放配置。支持通过 `kOff` 禁用。
- `ResolutionBitrateLimits`：特定分辨率下的推荐码率范围。
- `Resolution`：宽高描述。
- `EncoderInfo`：编码器元信息，包含 scaling_settings、fps_allocation、supports_simulcast、implementation_name、is_hardware_accelerated 等。
- `RateControlParameters`：码率控制参数（target_bitrate、bitrate、framerate_fps、bandwidth_allocation）。
- `LossNotification`：丢包通知，包含接收端反馈的帧依赖信息，用于编码器决策参考帧。
- `Capabilities`：协商的编码器能力。
- `Settings`：编码器设置（capabilities、number_of_cores、max_payload_size）。

**纯虚函数**：
- `RegisterEncodeCompleteCallback` / `Release` / `Encode` / `SetRates` / `GetEncoderInfo`。

**静态方法**：
- `GetDefaultVp8Settings()` / `GetDefaultVp9Settings()` / `GetDefaultH264Settings()`：返回各编解码器默认配置。

## 实现文件 (.cc)

**默认编码器设置**：各编解码器的默认参数：
- VP8/VP9 默认 1 个时间层，去噪开启，关键帧间隔 3000 帧、自适应 QP（仅 VP9）、自适应分辨率缩放（仅 VP9）。
- H264 默认关键帧间隔 3000 帧、1 个时间层。

**EncoderInfo 默认值**：
- scaling_settings 默认为 kOff（无自适应缩放）。
- requested_resolution_alignment = 1。
- fps_allocation 初始化为单个 100%。
- is_hardware_accelerated 默认 true。
- preferred_pixel_formats 默认仅 I420。

**`EncoderInfo::GetEncoderBitrateLimitsForResolution`**：
- 按分辨率排序 `resolution_bitrate_limits`，找到第一个大于等于目标分辨率的码率限制。
- 实现中包含 DCHECK 验证数据的单调递增性（分辨率越高，码率限制越高）。

**`InitEncode` 的默认实现**：
- 提供两个重载版本的相互委托，避免了堆栈溢出——实际子类至少会重载一个版本。

## 学习扩展

- `fps_allocation` 是一个二维数组（空间层 x 时间层），每层用 8-bit 分数表示帧率比例。例如 `[255, 128]` 表示 TL0 占一半帧，TL1 占另一半（但 TL1 依赖 TL0，所以总帧率为 100%）。
- `ScalingSettings::kOff` 通过一个私有的 `KOff` 标记类型实现，避免了使用布尔标志，代码可读性更好。
- `RateControlParameters` 中的 `bandwidth_allocation` 表示网络实际可用带宽，可能高于编码器目标码率。
- 编码器接口的演进方向：`VideoEncoder` 正在被新的 `VideoEncoderInterface` 逐步取代，新接口提供更精细的帧级控制和 SVC 支持。

## 设计模式

**模板方法模式**：`VideoEncoder` 定义了编码器的生命周期接口，具体编码器实现重载纯虚函数来自定义行为。

**策略模式**：`EncodedImageCallback` 作为编码完成后的回调策略，不同的上层模块可以实现不同的处理逻辑（如 RTP 打包、统计收集等）。

**参数对象模式**：大量使用嵌套结构体（`Settings`、`RateControlParameters`、`EncoderInfo`）封装复杂配置，避免接口方法参数过多。
