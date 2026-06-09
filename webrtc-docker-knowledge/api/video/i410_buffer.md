# i410_buffer

## 概述

`I410Buffer` 是 WebRTC 中 I410 格式视频帧缓冲区的具体实现。I410 是一种 YUV 4:4:4 平面格式，每个像素分量用 16 位存储、10 位有效颜色信息（即 10-bit 4:4:4）。该类继承自 `I410BufferInterface`，提供内存管理、拷贝、旋转、格式转换和缩放等操作。I410 格式无任何色度子采样，RGB/YUV 各分量分辨率相同。

## 头文件接口 (.h)

- **静态工厂方法**：`Create(int width, int height)` 和带 stride 参数的重载，`Copy()` 两个重载（从 I410 缓冲区和从原始数据）、`Rotate()`。
- **与 I210Buffer/I010Buffer 的不同**：提供了 `Copy()` 接收外部数据指针的重载，以及 `InitializeData()` 方法（用于解决内存检查工具和 ffmpeg 的兼容性问题）。
- **接口实现**：`width()`、`height()`、`DataY/U/V()`、`StrideY/U/V()`、`ToI420()`。
- **可变访问器**：`MutableDataY()`、`MutableDataU()`、`MutableDataV()`。

## 实现文件 (.cc)

- **内存布局**：Y 平面起始于 `data_`，U 平面在 `data_ + stride_y * height`，V 平面在 `data_ + stride_y * height + stride_u * height`。Y/U/V 三个平面的分辨率完全相同（4:4:4）。
- **数据大小**：`kBytesPerPixel * (y * h + u * h + v * h)`。
- **格式转换**：
  - `ToI420()`：使用 `libyuv::I410ToI420` 将 10-bit 4:4:4 降级为 8-bit 4:2:0。
  - `Rotate()`：使用 `libyuv::I410Rotate`。
  - `CropAndScaleFrom()`：使用 `libyuv::I444Scale_16`。由于无子采样，裁剪偏移量直接用于 Y、U、V 三个平面。
- **`InitializeData()`**：将整个缓冲区置零，解决 `libyuv` 和 `ffmpeg` 在内存检查时的异常表现。

## 学习扩展

- **4:4:4 子采样**：无任何色度子采样，Y、U、V 三个平面分辨率完全相同。因此 chroma siting 概念不再重要，是最高质量的 YUV 格式之一。
- I410、I210、I010 的命名约定：I=平面 YUV，第一数字代表色度子采样（0=4:2:0、2=4:2:2、4=4:4:4），10 代表 10-bit 深度。

## 设计模式

**工厂方法模式（Factory Method）**：提供多个静态工厂方法创建实例。**适配器模式（Adapter）**：`ToI420()` 实现将 I410 适配为 WebRTC 中通用的 I420 格式。
