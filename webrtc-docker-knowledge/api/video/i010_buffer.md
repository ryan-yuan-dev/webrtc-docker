# i010_buffer

## 概述

`I010Buffer` 是 WebRTC 中 I010 格式视频帧缓冲区的具体实现。I010 是一种 YUV 4:2:0 平面格式，每个像素分量用 16 位存储、10 位有效颜色信息。该类继承自 `I010BufferInterface`，提供内存管理、拷贝、旋转、格式转换和缩放的完整能力。

## 头文件接口 (.h)

- **静态工厂方法**：
  - `Create(int width, int height)`：创建指定尺寸的 I010 缓冲区。
  - `Copy(const I010BufferInterface&)`：从已有的 I010 缓冲区拷贝。
  - `Copy(const I420BufferInterface&)`：从 I420 缓冲区上转换到 I010。
  - `Rotate(const I010BufferInterface&, VideoRotation)`：旋转。
- **接口实现**：`width()`、`height()`、`DataY()`、`DataU()`、`DataV()`、`StrideY()`、`StrideU()`、`StrideV()`、`ToI420()`。
- **可变访问器**：`MutableDataY()`、`MutableDataU()`、`MutableDataV()`，提供写入能力的指针。
- **缩放**：`CropAndScaleFrom()`（裁剪并缩放）和 `ScaleFrom()`（整体缩放）。
- **内存对齐**：使用 `AlignedFreeDeleter` 管理内存、支持 64 字节对齐。

## 实现文件 (.cc)

- **内存布局**：Y 平面起始于 `data_`，U 平面在 `data_ + stride_y * height`，V 平面在 `data_ + stride_y * height + stride_u * ((height + 1) / 2)`。每个像素 2 字节。
- **数据大小**：`kBytesPerPixel * (y * h + (u + v) * ((h + 1) / 2))`，因为 4:2:0 的色度高度是亮度的一半。
- **格式转换**：
  - `Copy(I420)` 使用 `libyuv::I420ToI010` 将 8 位 I420 上转换为 10 位 I010。
  - `ToI420()` 使用 `libyuv::I010ToI420` 降级为 I420。
  - `Rotate()` 使用 `libyuv::I010Rotate`。
  - `CropAndScaleFrom()` 使用 `libyuv::I420Scale_16`，裁剪偏移量会自适应对齐到偶数像素。

## 学习扩展

- **I010 vs I420**：I010 是 I420 的 10 位深度版本，色度子采样方式相同（4:2:0），但每个分量使用 uint16_t 存储（仅低 10 位有效）。因此处理 HDR 和宽色域视频时精度更高。
- **libyuv**：Google 开源的 YUV 图像处理库，WebRTC 依赖 libyuv 完成格式转换、旋转和缩放操作。

## 设计模式

**工厂方法模式（Factory Method）**：通过静态 `Create()` 和 `Copy()` 方法创建 I010Buffer 实例，隐藏了复杂的构造逻辑（如内存分配和对齐）。
