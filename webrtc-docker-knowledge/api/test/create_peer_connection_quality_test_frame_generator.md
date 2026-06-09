# create_peer_connection_quality_test_frame_generator

## 概述

该模块提供 PeerConnection 端到端质量测试专用的帧生成器工厂函数。封装了通用帧生成器的创建逻辑，将其适配为以 `VideoConfig` 和 `ScreenShareConfig` 为输入的便捷接口，并包含屏幕共享配置的验证逻辑。

## 头文件接口 (.h)

### 工厂函数

| 函数 | 说明 |
|------|------|
| `CreateSquareFrameGenerator(config, type)` | 从 VideoConfig 创建方块帧生成器 |
| `CreateFromYuvFileFrameGenerator(config, filename)` | 从 YUV 文件创建帧生成器 |
| `CreateScreenShareFrameGenerator(config, screen_share_config)` | 创建屏幕共享帧生成器 |

## 实现文件 (.cc)

**`ValidateScreenShareConfig()`** — 验证屏幕共享配置：
- 使用默认幻灯片时，分辨率必须匹配 `kDefaultSlidesWidth` (1850) x `kDefaultSlidesHeight` (1110)。
- 如有滚动参数，滚动源宽度/高度必须 >= 视频配置的宽度/高度。
- 滚动持续时间必须 <= 幻灯片切换间隔。

**`CreateScreenShareFrameGenerator()`** 包含三种模式：
1. **生成幻灯片模式** (`generate_slides = true`) → 使用 `CreateSlideFrameGenerator`。
2. **静态幻灯片模式**（无滚动）→ 从 YUV 文件列表创建 `CreateFromYuvFileFrameGenerator`，每张幻灯片的帧重复次数基于 `slide_change_interval` 计算。
3. **滚动幻灯片模式** → 使用 `CreateScrollingInputFromYuvFilesFrameGenerator`，包含滚动和暂停阶段。

默认幻灯片资源文件：
- `web_screenshot_1850_1110.yuv`
- `presentation_1850_1110.yuv`
- `photo_1850_1110.yuv`
- `difficult_photo_1850_1110.yuv`

## 学习扩展

- **帧重复计数**: 根据 `slide_change_interval` 和帧率计算每张幻灯片需重复显示的帧数。
- **滚动 vs 静态**: 滚动模式模拟用户在文档上滑动视口的行为。

## 设计模式

- **工厂方法模式** — 根据屏幕共享配置选择不同的帧生成器创建策略。
- **验证器模式** — `ValidateScreenShareConfig` 提前检查配置合法性。
