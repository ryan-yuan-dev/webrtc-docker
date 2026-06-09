# i444_buffer

## 概述

`I444Buffer` 是 WebRTC 中 I444 格式视频帧缓冲区的具体实现。I444 是 YUV 4:4:4 平面格式，每个像素分量 8 位，无任何色度子采样。该类继承自 `I444BufferInterface`，提供创建、拷贝、旋转、格式转换和缩放等操作。

## 头文件接口 (.h)

- **静态工厂方法**：`Create()`（两种重载）、`Copy()`（从 I444 接口或从原始数据）、`Rotate()`。
- **特殊方法**：`InitializeData()`（置零）。
- **接口实现**：`width()`、`height()`、`DataY/U/V()`、`StrideY/U/V()`、`ToI420()`。
- **可变访问器**：`MutableDataY/U/V()`。
- **缩放**：`CropAndScaleFrom()`。

## 实现文件 (.cc)

- **内存布局**：Y 平面起始于 `data_`，U 平面在 `data_ + stride_y * height`，V 平面在 `data_ + stride_y * height + stride_u * height`。三个平面分辨率完全相同。
- **数据大小**：`y * h + u * h + v * h`。
- **构造函数**：默认 stride = width（Y 平面 stride 与宽度相同，UV 平面 stride 与 width 相同，因为无子采样）。
- **格式转换**：
  - `ToI420()`：使用 `libyuv::I444ToI420` 将 4:4:4 降采样为 4:2:0。
  - `Rotate()`：使用 `libyuv::I444Rotate`。
  - `CropAndScaleFrom()`：使用 `libyuv::I444Scale`，Y、U、V 三个平面使用相同的偏移量（无子采样不需对齐）。

## 学习扩展

- **4:4:4 格式**：保留所有颜色信息，无任何色度子采样。常用于高端视频制作、屏幕分享和计算机图形场景，在 WebRTC 中主要用于高质量屏幕共享编码。
- 由于无子采样，444 格式在编辑、颜色键控（chroma key）等任务中质量最高，但码率也最高。

## 设计模式

**工厂方法模式（Factory Method）**：通过静态方法创建实例。**适配器模式（Adapter）**：`ToI420()` 将 I444 格式转换为 WebRTC 内部标准 I420 格式。
