# vp8_temporal_layers

## 概述

`Vp8TemporalLayers` 是 VP8 时间层控制器的多流聚合实现。它实现了 `Vp8FrameBufferController` 接口，内部持有多个 `Vp8FrameBufferController` 实例（每个 Simulcast 流一个），通过委托转发实现对多流的统一管理。该类是 temporal layer 控制器体系中的上层协调者。

## 头文件接口 (.h)

**枚举 `Vp8TemporalLayersType`**：（已弃用）
- `kFixedPattern`：使用固定的 1-4 层重复模式。
- `kBitrateDynamic`：根据编码比特率在 1-2 层间动态分配。

**类 `Vp8TemporalLayers`**（final，继承 `Vp8FrameBufferController`）：
- 构造函数接收 `Vp8FrameBufferController` 指针向量和 `FecControllerOverride`。
- 所有方法均接收 `stream_index` 参数，以支持多 Simulcast 流的独立控制。

**方法**：
- `SetQpLimits` / `StreamCount` / `SupportsEncoderFrameDropping` / `OnRatesUpdated` / `UpdateConfiguration` / `NextFrameConfig` / `OnEncodeDone` / `OnFrameDropped`：均按 stream_index 委托给对应的控制器。
- `OnPacketLossRateUpdate` / `OnRttUpdate` / `OnLossNotification`：网络条件相关通知，广播到所有控制器。

## 实现文件 (.cc)

**构造函数**：验证控制器列表非空且无空指针。如果 FecControllerOverride 存在，允许 FEC。

**委托实现**：单流委托方法（`SetQpLimits`、`NextFrameConfig` 等）转发时始终使用 `stream_index` 参数和控制器内部索引 0——这表明每个控制器管理一个 Simulcast 流的 temporal layer。

**广播方法**：`OnPacketLossRateUpdate`、`OnRttUpdate`、`OnLossNotification` 遍历所有控制器广播通知。

## 学习扩展

- 该类实现了一个"聚合器"模式，将多个 Vp8FrameBufferController 实例组合为一个统一的接口，使得上层（如 VP8 编码器）可以透明地管理多流 temporal layer。
- 委托时 controller 内部索引固定为 0，这意味着每个 controller 实例被设计为只管理一个流——stream_index 对应 Simulcast 流的索引。
- 此设计是 Simulcast 和 SVC 场景下的通用架构：每个流有自己的 temporal layer 控制器，但通过聚合器统一对外接口。

## 设计模式

**代理模式（Proxy）**：`Vp8TemporalLayers` 作为多个 `Vp8FrameBufferController` 实例的代理，统一管理 Simulcast 多流的时间层控制职责。

**组合模式（Composite）**：将多个控制器实例组合为一个统一的接口。广播类方法（如网络条件更新）递归到所有子控制器，委托类方法（如帧配置）根据 stream_index 路由到特定控制器。

**单例委托**：所有委托方法使用固定的内部索引 0，反映了"一个控制器管理一个流"的设计约束。
