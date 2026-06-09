# frame_generator_interface

## 概述

`frame_generator_interface` 定义了 `FrameGeneratorInterface` 抽象接口，用于在测试中生成视频帧数据。该接口是 WebRTC 测试框架中视频输入的统一抽象。

## 头文件接口 (.h)

### `FrameGeneratorInterface` 抽象类

内部数据结构：

- **`Resolution`** — 分辨率结构体（width, height）。
- **`VideoFrameData`** — 视频帧数据容器，包含 `VideoFrameBuffer` 和可选的 `UpdateRect`。

**`OutputType` 枚举**：

| 值 | 说明 |
|------|------|
| `kI420` | I420 格式（YUV 4:2:0 平面式） |
| `kI420A` | I420 + Alpha 通道 |
| `kI010` | 10-bit I420 |
| `kNV12` | NV12 格式 |

核心接口方法：

| 方法 | 说明 |
|------|------|
| `NextFrame()` | 返回下一帧数据（`VideoFrameData`） |
| `SkipNextFrame()` | 跳过下一帧，默认调用 NextFrame 并丢弃 |
| `ChangeResolution(width, height)` | 改变输出分辨率 |
| `GetResolution()` | 返回当前分辨率 |
| `fps()` | 返回数据源的帧率，可能为 `nullopt` |

## 实现文件 (.cc)

- `OutputTypeToString()` — 将 OutputType 枚举转换为可读字符串。

## 学习扩展

- **VideoFrameBuffer**: WebRTC 中视频帧缓冲区的抽象接口，支持多种像素格式。
- **UpdateRect**: 视频帧中相较于上一帧发生变化的矩形区域，用于编码优化。

## 设计模式

- **抽象基类模式** — 定义帧生成器接口，具体生成策略由子类实现。
- **迭代器模式** — `NextFrame()` 提供按顺序访问帧序列的能力。
