# video_bitrate_allocation

## 概述

`VideoBitrateAllocation` 是 WebRTC 中描述视频码率在空间层（Spatial Layer）和时间层（Temporal Layer）上分配的核心数据结构。它以三维矩阵的形式存储每个层组合的码率值（bps），并提供聚合查询、Simulcast 分解、字符串序列化等功能。该结构体是码率控制决策的输出载体。

## 头文件接口 (.h)

- **常量**：`kMaxBitrateBps = uint32_t::max`。
- **核心方法**：
  - `SetBitrate(spatial_index, temporal_index, bitrate_bps)`：设置指定层组合的码率。返回 false 表示总和超出 `kMaxBitrateBps`。
  - `HasBitrate()` / `GetBitrate()`：查询码率。
  - `IsSpatialLayerUsed()`：查询某个空间层是否有码率设置。
  - `GetSpatialLayerSum()`：获取某个空间层的总码率（所有时间层之和）。
  - `GetTemporalLayerSum()`：获取某个空间层从时间层 0 到指定索引的累积码率。
  - `GetTemporalLayerAllocation()`：返回指定空间层中各时间层的码率向量。
  - `GetSimulcastAllocations()`：将多空间层分配拆分为每个空间层独立的 `VideoBitrateAllocation` 对象。
  - `get_sum_bps()` / `get_sum_kbps()`：获取总码率。
  - `set_bw_limited()` / `is_bw_limited()`：标记分配是否受到带宽限制。
- **私有存储**：`std::optional<uint32_t> bitrates_[kMaxSpatialLayers][kMaxTemporalStreams]`。

## 实现文件 (.cc)

- **`SetBitrate()`**：更新单个层码率，同时维护总码率 `sum_`。若更新后超过 `kMaxBitrateBps` 则拒绝更新。
- **`GetSimulcastAllocations()`**：遍历所有空间层，将有值（used）的层拆分为独立的 `VideoBitrateAllocation`（所有层的 temporal index 归入单一空间层 index 0）。
- **`ToString()`**：格式化输出各空间层和对应的各时间层码率值，格式清晰展示多层结构。

## 学习扩展

- **kMaxSpatialLayers** 和 **kMaxTemporalStreams**：定义在 `video_codec_constants.h` 中，分别限制最大空间层数和最大时间层数。
- **非累积性说明**：注释强调每个层的码率是独立的，不是下层累加的结果。使用者需要根据层之间的依赖关系自行聚合。
- **Simulcast 拆解**：`GetSimulcastAllocations()` 方法将 SVC 的层间分配映射为 Simulcast 的独立流分配，便于配置发送器。

## 设计模式

**矩阵/数据容器模式**：使用二维数组管理码率数据，提供多维度的查询和聚合方法。`std::optional` 的使用允许明确区分"未设置"和"设置为 0"，后者表示"显式关闭"信号。
