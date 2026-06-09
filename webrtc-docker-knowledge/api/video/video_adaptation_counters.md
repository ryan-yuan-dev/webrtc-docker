# video_adaptation_counters

## 概述

`VideoAdaptationCounters` 是一个简单的计数结构体，用于统计视频流因资源过载而发生的自适应调整次数。当前支持两类自适应维度：分辨率（resolution_adaptations）和帧率（fps_adaptations）。该结构体广泛应用于 WebRTC 的视频质量自适应模块中，追踪资源受限时的降级历史。

## 头文件接口 (.h)

- **两个整数字段**：`resolution_adaptations`（分辨率自适应次数）和 `fps_adaptations`（帧率自适应次数），均确保非负。
- **`Total()`**：返回两类调整的总和。
- **运算符**：`operator==`、`operator!=`、`operator+`。
- **`ToString()`**：序列化为可读字符串。

## 实现文件 (.cc)

- **运算符重载**：`operator+` 将两个计数器的对应字段相加，用于合并多个资源或多次调整的计数。
- **`ToString()`**：格式为 `{ res=N fps=M }`。

## 学习扩展

- 分辨率自适应：当网络或 CPU 资源不足时，降低编码分辨率（例如从 720p 降至 480p 或 360p）。
- 帧率自适应：当计算资源不足时，降低编码帧率（例如从 30fps 降至 15fps）。
- 这两个维度的自适应策略在 `VideoStreamEncoder` 和 `VideoAdapter` 中协调执行。

## 设计模式

**值对象模式（Value Object）**：轻量级的不可变风格数据对象（字段公开但提供安全的构造保证），封装了基本的运算操作。可聚合（`operator+`）以适应复合自适应场景。
