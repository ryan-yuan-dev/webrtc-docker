# create_frame_generator

## 概述

`create_frame_generator` 模块提供了一系列工厂函数，用于创建各种类型的 `FrameGeneratorInterface` 帧生成器。这些生成器用于测试环境中产生不同的视频帧输入数据，支持多种数据来源和输出格式。

## 头文件接口 (.h)

### 工厂函数

| 函数 | 说明 |
|------|------|
| `CreateSquareFrameGenerator(width, height, type, num_squares)` | 生成带有随机移动小方块的测试帧，默认输出 I420，默认 10 个方块 |
| `CreateFromYuvFileFrameGenerator(filenames, width, height, frame_repeat_count)` | 从 YUV 文件集重复播放 |
| `CreateFromNV12FileFrameGenerator(filenames, width, height, frame_repeat_count)` | 从 NV12 文件集重复播放 |
| `CreateFromIvfFileFrameGenerator(env, filename, fps_hint)` | 从 IVF 文件生成帧 |
| `CreateScrollingInputFromYuvFilesFrameGenerator(clock, filenames, ...)` | 从 YUV 文件创建滚动输入，支持视口在源图像上滚动 |
| `CreateSlideFrameGenerator(width, height, frame_repeat_count)` | 生成随机填充彩色方块的幻灯片式帧 |

## 实现文件 (.cc)

- `CreateSquareFrameGenerator` → 创建 `SquareGenerator`。
- `CreateFromYuvFileFrameGenerator` → 打开 YUV 文件，创建 `YuvFileGenerator`。
- `CreateFromNV12FileFrameGenerator` → 打开 NV12 文件，创建 `NV12FileGenerator`。
- `CreateFromIvfFileFrameGenerator` → 创建 `IvfVideoFrameGenerator`，使用 `Environment` 中的时钟信息。
- `CreateScrollingInputFromYuvFilesFrameGenerator` → 创建 `ScrollingImageFrameGenerator`。
- `CreateSlideFrameGenerator` → 创建 `SlideGenerator`。

所有文件打开使用 `fopen`，如果失败则通过 `RTC_DCHECK` 断言。

## 学习扩展

- **YUV 和 NV12 格式**: 原始视频格式，YUV 是亮度+色度分量，NV12 是 YUV 4:2:0 的常见变体。
- **IVF 格式**: 用于存储 VP8/VP9/AV1 编码视频的容器格式。
- **帧生成器的用途**: 在 WebRTC 测试中模拟视频输入流，避免依赖真实摄像头。

## 设计模式

- **工厂方法模式** — 多个 `Create*()` 函数根据输入参数创建不同类型的帧生成器。
- **策略模式** — 不同的帧生成策略（方块、文件、滚动、幻灯片）各自独立实现。
