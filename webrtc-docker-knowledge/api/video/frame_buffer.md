# frame_buffer

## 概述

`FrameBuffer` 是 WebRTC 中视频帧接收缓冲区，核心功能是将从网络收到的乱序帧按帧 ID 排序并组装成可解码的时间单元（Temporal Unit）。它维护帧的连续性（Continuity）和可解码性（Decodability）状态，保证解码器获得有序、依赖完整的帧序列。该类是线程不安全的。

## 头文件接口 (.h)

- **结构体 `DecodabilityInfo`**：记录下一个和最后一个可解码时间单元的 RTP 时间戳。
- **构造函数**：
  - `FrameBuffer(int max_size, int max_decode_history, const FieldTrialsView& field_trials)`：`max_size` 是缓冲区最大帧数，`max_decode_history` 记录已解码帧的回溯区间。
- **核心方法**：
  - `InsertFrame()`：插入一帧，要求帧引用只能向后、无重复引用、帧 ID 唯一且未被解码过。失败条件包括重复帧、缓冲区满且非关键帧等。
  - `ExtractNextDecodableTemporalUnit()`：提取并返回下一个可解码的时间单元（一组帧），同时标记这些帧为已解码。
  - `DropNextDecodableTemporalUnit()`：丢弃下一个可解码时间单元。
  - `LastContinuousFrameId()` / `LastContinuousTemporalUnitFrameId()`：查询连续帧/时间单元的 ID。
  - `DecodableTemporalUnitsInfo()`：查询可解码时间单元信息。
  - `CurrentSize()` / `GetTotalNumberOf*()`：状态统计。

## 实现文件 (.cc)

- **内部数据结构**：
  - `FrameMap`：`std::map<int64_t, FrameInfo>`，键为帧 ID，值包含 `EncodedFrame` 指针和 `continuous` 标志。
  - `TemporalUnit`：包含 `first_frame` 和 `last_frame` 两个迭代器，标记时间单元的范围。
- **帧插入流程**：
  1. `ValidReferences()` 校验：所有参考帧 ID 必须小于自身 ID，且无重复引用。
  2. 检查帧是否已解码（通过 `decoded_frame_history_`）。
  3. 检查缓冲区是否已满，若已满则只允许关键帧插入（会清理整个缓冲区）。
  4. 插入后调用 `PropagateContinuity()` 传播连续性，然后调用 `FindNextAndLastDecodableTemporalUnit()` 更新可解码状态。
- **连续性传播**：`IsContinuous()` 递归检查帧的所有参考帧是否已在解码历史中或连续。连续帧会更新 `last_continuous_frame_id_` 和 `num_continuous_temporal_units_`。
- **可解码时间单元查找**：遍历缓冲区，找到时间戳相同的帧组作为时间单元。如果单元内所有帧的参考都能在已解码帧或本单元内找到，则该单元可解码。
- **Field Trials**：`legacy_frame_id_jump_behavior_` 控制旧版帧 ID 跳跃行为兼容性。

## 学习扩展

- **Temporal Unit**：RTP 时间戳相同的帧构成一个时间单元。在 SVC 编码中，一个时间单元可能包含多个空间层的帧。
- **帧连续性 vs 可解码性**：连续帧指所有参考帧都已被解码或连续；可解码时间单元指单元内帧的参考都在已解码帧或本单元内。
- 缓冲区满时的关键帧插入会清空整个缓冲区，这是保证关键帧能被尽快解码的重要设计。

## 设计模式

**状态模式（State）**：FrameInfo 中的 `continuous` 标志和 `decoded_frame_history_` 的 `WasDecoded()` 共同构成帧的状态管理。`PropagateContinuity()` 实现了状态传播机制。
