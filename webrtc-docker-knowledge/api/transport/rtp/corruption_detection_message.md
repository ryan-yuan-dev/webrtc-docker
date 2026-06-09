# corruption_detection_message

## 概述

`corruption_detection_message.h` / `corruption_detection_message.cc` 定义了视频帧损坏检测消息的数据结构。该模块用于在 RTP 扩展头中传递视频帧的校验信息，使接收端能够检测视频帧在传输过程中是否发生了数据损坏。

该机制通过 Halton 序列对视频帧进行结构化采样，然后比较发送端和接收端的采样值来判断帧是否损坏。

## 头文件接口 (.h)

**文件**: `api/transport/rtp/corruption_detection_message.h`

### CorruptionDetectionMessage

```cpp
class CorruptionDetectionMessage {
 public:
  class Builder;

  CorruptionDetectionMessage();
  CorruptionDetectionMessage(const CorruptionDetectionMessage&) = default;

  int sequence_index() const;
  bool interpret_sequence_index_as_most_significant_bits() const;
  double std_dev() const;
  int luma_error_threshold() const;
  int chroma_error_threshold() const;
  ArrayView<const double> sample_values() const;

  static CorruptionDetectionMessage FromFrameInstrumentationData(
      const FrameInstrumentationData& frame_instrumentation);
};
```

### 字段说明

| 字段 | 类型 | 范围 | 说明 |
|------|------|------|------|
| `sequence_index_` | int | [0, 2^7-1] | Halton 序列索引，确定采样点坐标 |
| `interpret_sequence_index_as_most_significant_bits_` | bool | true/false | 是否将 sequence_index 解释为真序列索引的高位 |
| `std_dev_` | double | [0, 40.0] | 高斯滤波核标准差 |
| `luma_error_threshold_` | int | [0, 15] | 亮度层损坏检测阈值 |
| `chroma_error_threshold_` | int | [0, 15] | 色度层损坏检测阈值 |
| `sample_values_` | InlinedVector<double, 13> | [0, 255] | 高斯滤波后的采样值列表（最多 13 个） |

### Builder (建造者模式)

```cpp
class CorruptionDetectionMessage::Builder {
 public:
  std::optional<CorruptionDetectionMessage> Build();

  Builder& WithSequenceIndex(int sequence_index);
  Builder& WithInterpretSequenceIndexAsMostSignificantBits(bool value);
  Builder& WithStdDev(double std_dev);
  Builder& WithLumaErrorThreshold(int luma_error_threshold);
  Builder& WithChromaErrorThreshold(int chroma_error_threshold);
  Builder& WithSampleValues(const ArrayView<const double>& sample_values);
};
```

- 使用链式调用风格设置各字段
- `Build()` 返回 `std::optional`，在字段验证失败时返回 `std::nullopt`

## 实现文件 (.cc)

**文件**: `api/transport/rtp/corruption_detection_message.cc`

### FromFrameInstrumentationData

从 `FrameInstrumentationData` 构造 `CorruptionDetectionMessage` 的静态工厂方法：

```cpp
CorruptionDetectionMessage
CorruptionDetectionMessage::FromFrameInstrumentationData(
    const FrameInstrumentationData& frame_instrumentation) {
  int transmitted_sequence_index =
      frame_instrumentation.holds_upper_bits()
          ? frame_instrumentation.sequence_index() >> 7
          : (frame_instrumentation.sequence_index() & 0b0111'1111);
  Builder builder;
  builder.WithSequenceIndex(transmitted_sequence_index)
      .WithInterpretSequenceIndexAsMostSignificantBits(
          frame_instrumentation.holds_upper_bits());
  if (!frame_instrumentation.is_sync_only()) {
    builder.WithStdDev(frame_instrumentation.std_dev())
        .WithLumaErrorThreshold(frame_instrumentation.luma_error_threshold())
        .WithChromaErrorThreshold(
            frame_instrumentation.chroma_error_threshold())
        .WithSampleValues(frame_instrumentation.sample_values());
  }
  // ...
}
```

关键逻辑：
- 当 `holds_upper_bits() == true` 时，`sequence_index` 取原索引的高 7 位；否则取低 7 位
- `is_sync_only()` 为 true 时不传输采样数据，仅用于同步 `sequence_index`

### Builder::Build

完整的参数验证：

```cpp
std::optional<CorruptionDetectionMessage> Build() {
  // sequence_index: 0 ~ 0b0111'1111 (127)
  if (message_.sequence_index_ < 0 || message_.sequence_index_ > 0b0111'1111)
    return std::nullopt;
  // std_dev: 0 ~ 40.0
  if (message_.std_dev_ < 0.0 || message_.std_dev_ > kMaxStdDev)
    return std::nullopt;
  // luma/chroma error threshold: 0 ~ 15
  if (message_.luma_error_threshold_ < 0 || message_.luma_error_threshold_ > kMaxErrorThreshold)
    return std::nullopt;
  if (message_.chroma_error_threshold_ < 0 || message_.chroma_error_threshold_ > kMaxErrorThreshold)
    return std::nullopt;
  // sample_values: 最多 13 个，每个值在 0 ~ 255
  if (message_.sample_values_.size() > kMaxSampleSize)
    return std::nullopt;
  for (double sample_value : message_.sample_values_) {
    if (sample_value < 0.0 || sample_value > 255.0)
      return std::nullopt;
  }
  return message_;
}
```

### Builder 链式方法

每个 `With*` 方法直接设置内部 `message_` 的对应字段，返回 `*this` 以支持链式调用。

## 测试: corruption_detection_message_unittest.cc

**文件**: `api/transport/rtp/corruption_detection_message_unittest.cc`

单元测试覆盖：
- `CorruptionDetectionMessage` 的默认构造和字段访问
- `FromFrameInstrumentationData` 的三种场景：同步帧、完整帧、高位/低位序列索引
- `Builder::Build` 的验证逻辑：合法值通过、非法值返回 nullopt
- `Builder` 链式调用的正确性

## 学习扩展

### Halton 序列采样

Halton 序列是一种低差异序列 (Low-discrepancy sequence)，用于在空间中生成立方分布均匀的采样点。在损坏检测中：

1. 发送端使用 Halton 序列确定视频帧上的采样点坐标
2. 对采样区域应用高斯滤波
3. 将滤波后的采样值、滤波参数和序列索引发送给接收端
4. 接收端在相同坐标进行相同的滤波操作
5. 比较两者的差异是否超过阈值，判断帧是否损坏

### 损坏检测与 RTP 头扩展

该消息结构需要配合 RTP 头扩展使用，嵌入到 RTP 包的扩展头部中传输。接收端解析 RTP 包时提取该信息，与本地计算值做比对。

### 为什么只传输最多 13 个采样值？

由于 RTP 头扩展的空间有限，需要在采样精度和带宽开销之间权衡。最多 13 个采样值足以对帧损坏做出较高置信度的判断，同时保持较低的开销。

## 设计模式

| 模式 | 出现位置 | 说明 |
|------|----------|------|
| **Builder** | `CorruptionDetectionMessage::Builder` | 分步设置字段，最终 build 时进行完整性验证 |
| **Factory Method** | `FromFrameInstrumentationData` | 从另一种数据格式创建本对象 |
| **Value Object** | `CorruptionDetectionMessage` | 不可变对象，通过 getter 访问字段 |
