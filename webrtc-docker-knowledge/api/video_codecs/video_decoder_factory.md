# video_decoder_factory

## 概述

`VideoDecoderFactory` 是 WebRTC 中创建视频解码器的工厂抽象接口。它定义了获取解码器支持格式列表、查询编解码支持能力以及创建解码器实例的标准方法。所有实际的解码器工厂（如内置工厂、外部注入工厂）都需实现此接口。

## 头文件接口 (.h)

**嵌套结构体 `CodecSupport`**：
- `is_supported`：格式是否受支持。
- `is_power_efficient`：是否节能（通常指示是否有硬件加速支持）。

**纯虚函数**：
- `GetSupportedFormats()`：返回按偏好排序的 `SdpVideoFormat` 列表。
- `Create(env, format)`：根据指定格式创建 `VideoDecoder` 实例。

**虚函数**：
- `QueryCodecSupport(format, reference_scaling)`：查询格式支持和功耗效率。`reference_scaling` 参数表示是否需要跨空间层的参考帧缩放支持。

## 实现文件 (.cc)

- `QueryCodecSupport` 的默认实现：从 `GetSupportedFormats` 中查找，如果 `reference_scaling` 为 true 则返回不支持（因为默认实现无法保证支持跨层参考缩放）。

## 学习扩展

- 工厂接口的 `reference_scaling` 参数与 scalability modes 相关：当视频流使用空间层间依赖的可伸缩性模式时，解码器需要支持参考帧缩放能力。
- 接口注释"still under development"表明该类仍在演进中。实际上 WebRTC 正引入新的 `VideoDecoderFactoryInterface` 来替代此接口。
- `Create` 方法接受 `Environment` 参数，这是 WebRTC 新架构的一个特点——通过环境对象传递依赖。

## 设计模式

**抽象工厂模式**：`VideoDecoderFactory` 定义了创建一系列相关对象（不同编解码器的解码器）的抽象接口。具体工厂（如 `InternalDecoderFactory`）提供实际的创建逻辑。

**查询方法**：`QueryCodecSupport` 允许调用者在真正创建解码器之前先试探格式支持情况，是工厂模式中常见的扩展方法。
