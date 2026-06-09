# vp8_frame_config

## 概述

`Vp8FrameConfig` 描述 VP8 编码器单个帧的完整配置——包括三个参考缓冲区（Last、Golden、AltRef）的使用方式、帧类型、熵编码冻结、参考帧搜索顺序、重传策略和 temporal layer 索引。该结构体是 VP8 编码器与上层 temporal layer 控制器之间的关键数据交换接口。

## 头文件接口 (.h)

**结构体 `Vp8FrameConfig`**：

**枚举 `BufferFlags`**：
- `kNone` = 0：既不参考也不更新对应缓冲区。
- `kReference` = 1：参考该缓冲区。
- `kUpdate` = 2：更新该缓冲区。
- `kReferenceAndUpdate` = 3：既参考又更新。

**枚举 `Vp8BufferReference`**：
- `kLast` = 1、`kGolden` = 2、`kAltref` = 4：三个 VP8 可用的参考帧缓冲区的位掩码标识。

**关键字段**：
- `drop_frame`：是否丢弃该帧（当三个缓冲区的 flags 均为 kNone 时自动设置）。
- `last_buffer_flags` / `golden_buffer_flags` / `arf_buffer_flags`：三个缓冲区的使用方式。
- `encoder_layer_id`：编码器内部用于码率分配的层 ID。
- `packetizer_temporal_idx`：RTP 打包时使用的 temporal 层索引。
- `layer_sync`：是否为层同步点（允许解码器从该帧开始切换层而不产生依赖错误）。
- `freeze_entropy`：是否冻结熵编码上下文。
- `first_reference` / `second_reference`：运动预测的参考帧搜索顺序。
- `retransmission_allowed`：该帧是否允许 NACK 重传。

**静态方法**：
- `GetIntraFrameConfig()`：返回帧内编码（Intra frame）配置，更新所有三个缓冲区。

**成员函数**：
- `References(buffer)`：检查是否引用了指定缓冲区。
- `Updates(buffer)`：检查是否更新了指定缓冲区。
- `IntraFrame()`：检查是否为帧内编码帧（三个缓冲区均标记为 kUpdate）。

## 实现文件 (.cc)

**构造函数**：
- 默认构造函数：所有缓冲区 flags 为 kNone，导致 `drop_frame = true`。
- 带 `FreezeEntropy` 参数的构造函数：设置 `freeze_entropy = true`。
- 当所有三个缓冲区 flags 都为 kNone 时，`drop_frame` 自动设为 true。
- `packetizer_temporal_idx` 初始化为 `kNoTemporalIdx`（定义在 `common_constants.h`）。
- `first_reference` 和 `second_reference` 默认 `kNone`。

**References / Updates**：通过位掩码检查对应缓冲区 flags 中是否包含 kReference 或 kUpdate 位。

## 学习扩展

- VP8 的三个参考缓冲区（Last、Golden、AltRef）可以独立配置参考和更新模式，通过组合实现灵活的时间层预测结构。
- `encoder_layer_id` 和 `packetizer_temporal_idx` 的分离是 WebRTC 的特殊设计——对于屏幕共享场景，编码器可能使用一个"编码器层"但打包到不同的 temporal 层中。
- `freeze_entropy` 用于屏幕共享场景，在场景切换时重置上下文模型以降低比特率。
- `IntraFrame()` 并不检查是否没有引用缓冲区，而是检查是否更新了所有缓冲区，这也是关键帧的特征。

## 设计模式

**数据传输对象（DTO）**：`Vp8FrameConfig` 主要在 temporal layer 控制器和 VP8 编码器之间传递帧配置信息。其构造函数从 flags 推导 `drop_frame`，体现了简单的业务规则封装。

**位掩码标志模式**：使用枚举值的位运算组合参考和更新操作，是 C/C++ 中经典的标志位处理方式，比使用集合或向量更高效。
