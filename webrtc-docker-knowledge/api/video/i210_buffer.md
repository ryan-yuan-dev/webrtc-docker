# i210_buffer

## 概述

`I210Buffer` 是 WebRTC 中 I210 格式视频帧缓冲区的具体实现。I210 是一种 YUV 4:2:2 平面格式，每个像素分量用 16 位存储、10 位有效颜色信息（即 10-bit 4:2:2）。该类继承自 `I210BufferInterface`，提供内存管理、拷贝、旋转、格式转换和缩放等操作。

## 头文件接口 (.h)

- **静态工厂方法**：`Create()`、`Copy()`（从 I210 或 I420 拷贝）、`Rotate()`。
- **接口实现**：`width()`、`height()`、`DataY/U/V()`、`StrideY/U/V()`、`ToI420()`。
- **可变访问器**：`MutableDataY()`、`MutableDataU()`、`MutableDataV()`。
- **缩放**：`CropAndScaleFrom()` 和 `ScaleFrom()`。
- **内存对齐**：64 字节对齐，每个像素 2 字节。

## 实现文件 (.cc)

- **内存布局**：Y 平面起始于 `data_`，U 平面在 `data_ + stride_y * height`，V 平面在 `data_ + stride_y * height + stride_u * height`。4:2:2 格式下色度高度与亮度相同。
- **数据大小**：`kBytesPerPixel * (y * h + u * h + v * h)`，U/V 平面行数与 Y 相同。
- **格式转换**：
  - `Copy(I420)`：先通过 `I422Buffer::Copy(I420)` 上采样到 I422，再使用 `libyuv::I422ToI210` 扩展到 10 位。
  - `ToI420()`：使用 `libyuv::I210ToI420` 将 10-bit 4:2:2 转为 8-bit 4:2:0。
  - `Rotate()`：使用 `libyuv::I210Rotate`。
  - `CropAndScaleFrom()`：使用 `libyuv::I422Scale_16`，U/V 平面的裁剪偏移量在 x 方向除以 2（4:2:2 水平子采样），垂直方向不做除 2。

## 学习扩展

- **4:2:2 子采样**：色度水平方向降采样一半（每两个像素共享一个 UV 对），垂直方向保持完整。因此 luma plane 的 `width == height`，chroma plane 的 `ChromaWidth = (width+1)/2`、`ChromaHeight = height`。
- **I210 vs I010**：主要区别在色度垂直分辨率——I210 的 UV 高度与 Y 相同（4:2:2），I010 的 UV 高度为 Y 的一半（4:2:0）。

## 设计模式

**工厂方法模式（Factory Method）**：通过静态方法创建实例，隐藏内存分配和布局计算细节。**适配器模式（Adapter）**：`Copy(I420)` 方法实际上将 I420 适配为 I210 格式，承担了格式转换的角色。
