# nv12_buffer

## 概述

`NV12Buffer` 是 WebRTC 中 NV12 格式视频帧缓冲区的具体实现。NV12 是一种双平面 YUV 格式：Y 平面为全分辨率单色，UV 平面为半分辨率交错存储。该类继承自 `NV12BufferInterface`，在 iOS/macOS/Windows 等平台硬件编码器中广泛使用。

## 头文件接口 (.h)

- **静态工厂方法**：`Create()`（两种重载）、`Copy()`（从 I420 缓冲区转换）。
- **接口实现**：`width()`、`height()`、`StrideY()`、`StrideUV()`、`DataY()`、`DataUV()`、`ToI420()`。
- **可变访问器**：`MutableDataY()`、`MutableDataUV()`。
- **特殊方法**：`InitializeData()`（置零）。
- **缩放**：`CropAndScaleFrom()`。
- **辅助方法**：`UVOffset()`，计算 UV 平面在内存中的起始偏移。

## 实现文件 (.cc)

- **内存布局**：单个 `data_` 缓冲区，Y 平面从偏移 0 开始，大小 `stride_y * height`；UV 平面从 `stride_y * height` 偏移开始，大小 `stride_uv * ((height + 1) / 2)`。
  - UV 平面中，U 和 V 交错排列：U0、V0、U1、V1...
- **数据大小**：`y * h + uv * ((h + 1) / 2)`。每个 UV 对覆盖 2x2 像素块。
- **默认 stride**：Y stride = width，UV stride = `width + width % 2`（对齐到偶数）。
- **格式转换**：
  - `Copy(I420)`：使用 `libyuv::I420ToNV12` 将 I420 转换为 NV12。
  - `ToI420()`：使用 `libyuv::NV12ToI420` 将 NV12 转换回 I420。
  - `CropAndScaleFrom()`：使用 `libyuv::NV12Scale`，U/V 平面的偏移量在 x 方向不做 /2（因为交错，U offset_x * 2），y 方向做 /2。

## 学习扩展

- **NV12 vs I420**：NV12 是双平面格式（Y 和 UV 交错），I420 是三平面格式（Y、U、V 分离）。NV12 是大多数硬件编码器（iOS VideoToolbox、Android MediaCodec、Intel QSV）的原生输入格式。
- **交错 UV**：U 和 V 在同一个平面中交替排列 (U0,V0,U1,V1,...)，这对 SIMD 优化更友好。

## 设计模式

**工厂方法模式（Factory Method）**：通过静态方法创建实例。**适配器模式（Adapter）**：提供 NV12 与 I420 格式间的双向转换，使 NV12 能被 WebRTC 内部基于 I420 的处理管线使用。
