# scalability_mode

## 概述

`scalability_mode` 定义 WebRTC 支持的可伸缩性模式（Scalability Mode）枚举。可伸缩性模式描述了视频编码中空间层（Spatial Layer）和时间层（Temporal Layer）的组合方式。WebRTC 遵循 W3C WebRTC SVC 规范（webrtc-svc）中定义的命名约定，本模块定义了所有在 API 边界（WebRTC 与注入编码器之间）可识别的模式。

## 头文件接口 (.h)

**枚举 `ScalabilityMode`**：定义了 40 种模式，命名格式为 `k{L|S}{层数}T{层数}[h][_KEY][_SHIFT]`：
- 前缀 `L` 表示空间层间有关联（Inter-layer prediction），`S` 表示空间层间独立。
- `T` 后的数字表示 temporal 层数。
- `h` 后缀表示空间层间缩放比例为 2/3（而非默认的 1/2）。
- `_KEY` 后缀表示仅关键帧启用层间预测。
- `_KEY_SHIFT` 是 `kL2T2_KEY` 的特殊变体。

**数组 `kAllScalabilityModes[]`**：列出所有支持的模式，用于遍历和计数。

**核心函数**：
- `ScalabilityModeToString(ScalabilityMode)`：将枚举转换为字符串形式（如 `"L1T3"`, `"S2T2h"`）。
- `ScalabilityModeToString(optional<ScalabilityMode>)`：重载版本，`nullopt` 返回 `"nullopt"`。

## 实现文件 (.cc)

- 使用 switch 语句将每个枚举值映射到对应的字符串标识符。
- 对无效值调用 `RTC_CHECK_NOTREACHED()` 触发断言。

## 学习扩展

- Scalability Mode 命名约定符合 W3C 规范：例如 `L2T3` 表示 2 个空间层（有关联预测）和 3 个时间层。
- PeerConnection 层的 API 使用字符串表示 scalability mode，仅在 API 边界（注入编码器）使用枚举。
- 时间层（Temporal Layer）通过帧率分层实现视频的时域可伸缩性；空间层（Spatial Layer）通过分辨率分层实现。
- `_KEY_SHIFT` 是 WebRTC 特有的模式，用于特定屏幕共享场景。

## 设计模式

**枚举映射模式**：将枚举值通过 switch 语句一一映射为字符串，这是 C++ 中最直接的类型-字符串转换方式。`kAllScalabilityModes` 数组提供可遍历的注册表，允许代码通过迭代来枚举所有已知模式。
