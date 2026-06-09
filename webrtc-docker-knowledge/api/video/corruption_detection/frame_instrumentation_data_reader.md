# frame_instrumentation_data_reader

## 概述

`FrameInstrumentationDataReader` 负责从 RTP 扩展消息（`CorruptionDetectionMessage`）中解析出 `FrameInstrumentationData`。它处理消息中的序列索引增量编码（区分高位消息和增量消息），维护已处理的序列索引状态以支持包裹恢复。

## 头文件接口 (.h)

- **核心方法**：`ParseMessage(const CorruptionDetectionMessage&)` 返回 `std::optional<FrameInstrumentationData>`。
- **私有状态**：`last_seen_sequence_index_`，记录上一个处理的序列索引。

## 实现文件 (.cc)

- **序列索引解析**：
  - 若 `interpret_sequence_index_as_most_significant_bits` 为 true：将消息中的序列索引左移 7 位作为高位（即 `sequence_index << 7`），表示此消息携带的是高位信息。
  - 否则：在低 7 位增量消息中，将消息中的序列索引与已存储的高位组合。如果发生包裹（当前值 < 上一个值的低 7 位），则将高位增加 0x80（即 128）。
- **更新 `last_seen_sequence_index_`**：`sequence_index + sample_values.size()`，因为消息中的序列索引指向第一个采样值的 Halton 索引。
- **数据填充**：如果采样值非空，设置标准差、阈值和采样值。

## 学习扩展

- **序列索引编码策略**：序列索引的高 7 位通过 `holds_upper_bits()` 的帧一次性传输，低 7 位变化则通过普通消息传输。这种设计减少了关键帧时的元数据开销。

## 设计模式

**解析器模式（Parser）**：`FrameInstrumentationDataReader` 是有状态的解析器，从网络消息格式的数据转换为内部数据对象。它维护了序列索引状态以处理分片传输的序列号。
