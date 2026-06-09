# i422_buffer

## 概述

`I422Buffer` 是 WebRTC 中 I422 格式视频帧缓冲区的具体实现。I422 是 YUV 4:2:2 平面格式，每个像素分量 8 位。该类继承自 `I422BufferInterface`，提供创建、拷贝、旋转、格式转换和缩放等操作。I422 在水平方向对色度进行 2x 子采样，垂直方向完整保留。

## 头文件接口 (.h)

- **静态工厂方法**：`Create()`（两种重载）、`Copy()`（从 I422 接口、从 I420 接口、从原始数据）、`Rotate()`。
- **特殊方法**：`SetBlack()`（静态置黑）、`InitializeData()`（置零）。
- **接口实现**：`width()`、`height()`、`DataY/U/V()`、`StrideY/U/V()`、`ToI420()`。
- **可变访问器**：`MutableDataY/U/V()`。
- **缩放方法**：两个 `CropAndScaleFrom()` 重载（指定参数版和自动居中版）、`ScaleFrom()`。

## 实现文件 (.cc)

- **内存布局**：Y 平面起始于 `data_`，U 平面在 `data_ + stride_y * height`，V 平面在 `data_ + stride_y * height + stride_u * height`。I422 的 UV 平面高度与 Y 平面相同。
- **数据大小**：`y * h + u * h + v * h`，三个平面高度相同。
- **格式转换**：
  - `Copy(I420)` 使用 `libyuv::I420ToI422` 将 4:2:0 上采样为 4:2:2（垂直方向插值）。
  - `ToI420()` 使用 `libyuv::I422ToI420` 降采样 YUV 4:2:2 为 4:2:0。
  - `Rotate()` 使用 `libyuv::I422Rotate`。
  - `CropAndScaleFrom()` 使用 `libyuv::I422Scale`，UV 偏移量在 x 方向进行 /2 对齐（水平子采样），垂直方向直接使用。

## 学习扩展

- **4:2:2 子采样**：常用于专业视频制作和广播电视领域，相比 4:2:0 保留了完整的垂直色度分辨率，在字幕、图形叠加场景下质量更好。
- **I422 在 WebRTC 中的角色**：主要作为中间转换格式存在，例如从 I420 到 I210 的上转换链路中会经过 I422。

## 设计模式

**工厂方法模式（Factory Method）**：提供多个静态工厂方法创建实例，包括从 I420 到 I422 的格式转换适配。**适配器模式（Adapter）**：`Copy(I420)` 和 `ToI420()` 实现了 I420 和 I422 的双向转换适配。
