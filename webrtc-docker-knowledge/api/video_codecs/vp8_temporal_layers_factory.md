# vp8_temporal_layers_factory

## 概述

`Vp8TemporalLayersFactory` 是 `Vp8FrameBufferControllerFactory` 接口的实现，负责创建 VP8 temporal layer 控制器。根据视频流的编码配置（普通模式 vs 屏幕共享模式），它为每个 Simulcast 流选择不同的控制器实现——`DefaultTemporalLayers`（常规时间层）或 `ScreenshareLayers`（屏幕共享优化）。

## 头文件接口 (.h)

**类 `Vp8TemporalLayersFactory`**（继承 `Vp8FrameBufferControllerFactory`）：
- `Create(env, codec, settings, fec_controller_override)`：根据 VideoCodec 配置创建 `Vp8FrameBufferController` 实例。
- `Clone()`：克隆工厂实例。

## 实现文件 (.cc)

**Create 逻辑**：
1. 通过 `SimulcastUtility::NumberOfSimulcastStreams(codec)` 获取 Simulcast 流数量。
2. 对每个流，获取 temporal layer 数量。
3. 判断是否为屏幕共享模式（`SimulcastUtility::IsConferenceModeScreenshare`）：如果是且为流索引 0，创建 `ScreenshareLayers`（最少 2 层）；否则创建 `DefaultTemporalLayers`。
4. 将所有控制器组合到 `Vp8TemporalLayers` 聚合器中返回。

**Clone 逻辑**：创建新的 `Vp8TemporalLayersFactory` 实例。

## 学习扩展

- `DefaultTemporalLayers` 支持标准的固定模式时间层（L1T1 到 L1T4），通过帧参考模式实现时间预测结构。
- `ScreenshareLayers` 是屏幕共享的专用实现，使用 2 层结构，码率分配更激进，以处理屏幕场景中的场景切换高频运动。
- `SimulcastUtility::IsConferenceModeScreenshare` 检测 `VideoCodec` 的 `legacy_conference_mode` 标志，这是历史遗留功能。
- 第 i 个流的时间层数通过 `SimulcastUtility::NumberOfTemporalLayers(codec, i)` 获取，在 Simulcast 场景中每个流可能有不同的时间层配置。

## 设计模式

**工厂方法模式**：`Vp8TemporalLayersFactory` 根据输入参数（codec 配置）决定创建 `DefaultTemporalLayers` 还是 `ScreenshareLayers`。客户端（VP8 编码器）通过工厂接口获取控制器实例，无需了解具体实现类。

**原型模式**：`Clone()` 方法提供了工厂实例的拷贝能力，使调用者可以复制工厂配置状态后独立使用。
