# video_codec

## 概述

`VideoCodec` 是 WebRTC 中用于描述视频编解码器配置的核心类。它是一个"历史的 de facto API"，正在逐步被迁移到新的接口。该类封装了编解码器的所有通用和特定参数——分辨率、码率、帧率、Simulcast 流配置、SVC 空间层、编码复杂度、帧丢弃等。它通过联合体（`VideoCodecUnion`）存储 VP8/VP9/H264/AV1 各自特有的编码参数。

## 头文件接口 (.h)

**枚举**：
- `VideoCodecComplexity`：编码复杂度，从 Low(-1) 到 Max(3)，用于控制 CPU 使用程度。
- `InterLayerPredMode`：SVC 层间预测模式（Off / On / OnKeyPic）。
- `VideoCodecMode`：模式（kRealtimeVideo / kScreensharing）。

**编解码器特定结构体**：
- `VideoCodecVP8`：`numberOfTemporalLayers`、`denoisingOn`、`automaticResizeOn`、`keyFrameInterval`。
- `VideoCodecVP9`：增加 `numberOfSpatialLayers`、`flexibleMode`、`interLayerPred`、`adaptiveQpMode`。
- `VideoCodecH264`：`keyFrameInterval`、`numberOfTemporalLayers`。
- `VideoCodecAV1`：`automatic_resize_on`。

**转换函数**：
- `CodecTypeToPayloadString(VideoCodecType)`：编解码器类型转 SDP 负载名称字符串。
- `PayloadStringToCodecType(string)`：反向转换。

**类 `VideoCodec`**：
- **公共属性**：`codecType`、`width`/`height`、`startBitrate`/`maxBitrate`/`minBitrate`、`maxFramerate`、`active`、`qpMax`、`numberOfSimulcastStreams`、`simulcastStream[]`、`spatialLayers[]`、`mode`、`timing_frame_thresholds`。
- **访问器**：
  - `GetScalabilityMode()` / `SetScalabilityMode()`：可伸缩性模式的管理。
  - `GetVideoEncoderComplexity()` / `SetVideoEncoderComplexity()`：复杂度管理。
  - `GetFrameDropEnabled()` / `SetFrameDropEnabled()`：帧丢弃开关。
  - `IsSinglecast()` / `IsSimulcast()` / `IsMixedCodec()`：编码模式判定。
- **编解码器特定访问器**：`VP8()`、`VP9()`、`H264()`、`AV1()`（每个有 const 和非 const 版本）。

## 实现文件 (.cc)

**构造与默认值**：`VideoCodec` 构造函数初始化所有字段为 0 或默认值，`codecType` 为 `kVideoCodecGeneric`，`mode` 为 `kRealtimeVideo`，`complexity_` 为 `kComplexityNormal`。

**相等性比较**：每个编解码器特定结构体实现了 `operator==` 比较所有相关字段。

**`ToString`**：生成格式化的配置摘要字符串，包含编解码器类型、模式、是否 singlecast 或 simulcast 以及各流的参数。

**`IsMixedCodec`**：遍历激活的 Simulcast 流，检查是否有多个不同编解码器格式（使用 `IsSameCodec` 比较）。

**编解码器类型转换**：
- `CodecTypeToPayloadString`：switch 映射枚举到字符串（VP8/VP9/AV1/AV1X/H264/Generic/H265）。
- `PayloadStringToCodecType`：大小写不敏感匹配。注意 `AV1X` 是 AV1 的别名，用于向后兼容（bugs.webrtc.org/13166）。

## 学习扩展

- 该类使用联合体 `VideoCodecUnion` 存储编解码器特定参数，这是一种节省内存的 C 风格做法，但类型安全性较低。注释中提到正在考虑替换为指针类型。
- `numberOfSimulcastStreams` 的语义较为复杂：它不仅表示 Simulcast 流的数量，在 SVC 场景或单流场景中也可以为 0 或 1。
- `CodecTypeToPayloadString` 函数导出了 `AV1X` 名称，用于兼容早期的 AV1 实现，这体现了 WebRTC 对向后兼容的重视。
- 时间帧配置有助于接收端评估延迟和抖动。

## 设计模式

**联合体（Union）模式**：使用 `VideoCodecUnion` 联合体存储不同编解码器的特定参数，在内存布局上紧凑高效，通过 codecType 字段区分当前使用的变体。访问器通过断言验证 codecType 匹配，提供一定的类型安全性。

**值对象（Value Object）**：`VideoCodec` 以及其内部结构体都是值类型，通过 ToString 提供诊断输出。
