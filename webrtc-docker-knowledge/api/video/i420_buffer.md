# i420_buffer

## 概述

`I420Buffer` 是 WebRTC 中 I420 格式视频帧缓冲区的核心实现，也是 WebRTC 视频管道中最常用的帧缓冲区类型。I420 是 YUV 4:2:0 平面格式，每个像素分量 8 位。该类继承自 `I420BufferInterface`，提供了创建、拷贝、旋转、裁切缩放、置黑等完整操作，是 WebRTC 内部软件编码器的标准帧格式。

## 头文件接口 (.h)

- **静态工厂方法**：`Create()`（两种重载，支持自定义 stride）、`Copy()`（从 I420 接口或从 VideoFrameBuffer 的弃用版本）、`Rotate()`。
- **特殊方法**：
  - `SetBlack()`：静态方法，将整个缓冲区设为黑色（Y=0, U=128, V=128）。
  - `InitializeData()`：所有平面置零，用于兼容性修复。
- **接口实现**：`width()`、`height()`、`DataY/U/V()`、`StrideY/U/V()`、`ToI420()`。
- **可变访问器**：`MutableDataY/U/V()`。
- **缩放方法**：两个 `CropAndScaleFrom()` 重载（指定裁剪参数版和自动居中裁剪版）、`ScaleFrom()`。

## 实现文件 (.cc)

- **内存布局**：Y 平面起始于 `data_`，U 平面在 `data_ + stride_y * height`，V 平面在 `data_ + stride_y * height + stride_u * ((height + 1) / 2)`。
- **数据大小**：`y * h + (u + v) * ((h + 1) / 2)`，I420 色度平面高度为亮度的一半（向上取整）。
- **格式转换**：`Copy` 使用 `libyuv::I420Copy`，`Rotate` 使用 `libyuv::I420Rotate`，`CropAndScaleFrom` 使用 `libyuv::I420Scale`。
- **`SetBlack()`**：通过 `libyuv::I420Rect` 将矩形区域填充为 Y=0、U=128、V=128。
- **自动居中裁剪**：`CropAndScaleFrom(const I420BufferInterface& src)` 根据目标宽高比自动计算源图中的中心裁剪区域。

## 学习扩展

- **I420（又名 IYUV）**：最广泛使用的 YUV 格式，WebRTC 内部软件编码器的首选输入格式。所有其他 YUV 格式（I444、I422、NV12 等）都需要能转换为 I420。
- **Stride（跨度/行步长）**：一行像素占用的实际字节数，可能大于宽度（因内存对齐）。在格式转换和内存操作中必须使用 stride 而非 width。
- **libyuv::kFilterBox**：Box 滤波是一种快速且常用的图像缩放算法。

## 设计模式

**工厂方法模式（Factory Method）**：提供丰富的静态工厂方法。**适配器模式（Adapter）**：所有 YUV 缓冲区（包括 kNative 类型）都需要实现 `ToI420()`，I420Buffer 本身返回 `this`，起到适配器中心的作用。
