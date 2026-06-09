# video_decoder

## 概述

`VideoDecoder` 是 WebRTC 中视频解码器的核心抽象接口。它定义了所有解码器实现必须遵守的契约，包括初始化（Configure）、解码（Decode）、回调注册、资源释放和元信息查询。本模块包含 `VideoDecoder` 接口类和 `DecodedImageCallback` 回调接口类。

## 头文件接口 (.h)

**类 `DecodedImageCallback`**：
- `Decoded(VideoFrame&)`：纯虚函数，解码完成后的回调。
- `Decoded(VideoFrame&, decode_time_ms)`：带解码时间的回调重载。
- `Decoded(VideoFrame&, decode_time_ms, qp)`：最完整版本的回调，包含 QP 信息。

**嵌套类型**：
- `VideoDecoder::DecoderInfo`：解码器元信息，包括 `implementation_name` 和 `is_hardware_accelerated`。
- `VideoDecoder::Settings`：配置参数，包括 `buffer_pool_size`、`max_render_resolution`、`number_of_cores`、`codec_type`。

**纯虚函数**：
- `Configure(const Settings&)`：配置解码器，可以多次调用，仅最后一次生效。
- `Decode(const EncodedImage&, render_time_ms)`：解码编码图像。目前有两个重载版本以兼容迁移期（`bool missing_frames` 参数逐步淘汰中）。
- `RegisterDecodeCompleteCallback(DecodedImageCallback*)`：注册解码完成回调。
- `Release()`：释放解码器资源。

**虚函数（有默认实现）**：
- `GetDecoderInfo()`：返回解码器信息（默认从 `ImplementationName()` 获取）。
- `ImplementationName()`：返回 `"unknown"`（已弃用，使用 `GetDecoderInfo`）。

## 实现文件 (.cc)

- `DecodedImageCallback::Decoded(VideoFrame&, int64_t)`：忽略自定义解码时间，调用简化版本。
- `DecodedImageCallback::Decoded(VideoFrame&, optional<decode_time_ms>, optional<qp>)`：同时处理时间和 QP，调用中间版本。
- `VideoDecoder::GetDecoderInfo()`：默认实现，使用 `ImplementationName()` 填充。
- `VideoDecoder::ImplementationName()`：返回 `"unknown"`。
- `DecoderInfo::ToString()`：格式化为可读字符串。
- `Settings::set_number_of_cores`：断言确保 `> 0`。

## 学习扩展

- `DecodedImageCallback` 的多个重载反映了 WebRTC 接口演化的历史：从最简单的 `Decoded(frame)` 到后来增加解码时间和 QP 信息以支持更精确的延迟估算和码率控制。
- `Settings` 中的 `buffer_pool_size` 允许解码器内部管理帧缓冲池的大小，其中 `nullopt` 表示使用编解码器默认值。
- `max_render_resolution` 通知解码器不需要处理超过该分辨率的图像，解码器可据此优化内部资源分配。
- `Configure` 的可重入设计允许编码器在运行过程中动态调整解码配置（如分辨率变化）。

## 设计模式

**模板方法模式**：使用继承层次定义解码器接口，子类实现所有纯虚函数，而基类提供默认实现和辅助功能。

**策略模式**：`DecodedImageCallback` 作为回调策略接口，解码完成后通知调用者。不同的调用者可以实现不同的回调逻辑（如渲染、统计、重排等）。

**参数对象模式**：使用 `Settings` 类封装多个配置参数，避免构造函数参数过多，同时便于未来扩展新配置项而不破坏接口兼容性。
