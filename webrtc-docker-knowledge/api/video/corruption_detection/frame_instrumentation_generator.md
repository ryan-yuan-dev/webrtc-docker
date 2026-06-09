# frame_instrumentation_generator

## 概述

`FrameInstrumentationGenerator` 是 WebRTC 视频质量检测（Corruption Detection）系统的发送端组件。它接收原始采集帧（`OnCapturedFrame`）和对应的编码图像（`OnEncodedImage`），对部分帧生成 `FrameInstrumentationData`。这些数据作为 RTP 头部扩展传输至接收端，供接收端验证视频流的完整性。生成器为每个空间层/Simulcast 层维护独立的 Halton 序列采样上下文。

## 头文件接口 (.h)

- **`Create(VideoCodecType)`**：静态工厂方法，创建生成器实例。
- **`OnCapturedFrame(VideoFrame)`**：输入采集的原始帧。
- **`OnEncodedImage(EncodedImage)`**：输入编码图像，返回 `std::optional<FrameInstrumentationData>`——有数据时表示该帧需要发送 corruption detection 信息。
- **`GetHaltonSequenceIndex(layer_id)` / `SetHaltonSequenceIndex(index, layer_id)`**：查询和设置 Halton 序列索引（用于测试或外部同步）。

## 实现文件 (.cc)

- **`FrameInstrumentationGeneratorImpl`**：
  - **成员**：`captured_frames_`（捕获帧队列，最大 2 帧）、`contexts_`（`map<int, Context>`，空间层 ID 到采样上下文）、`video_codec_type_`、`mutex_`。
  - **`Context` 结构**：包含 `HaltonFrameSampler` 和该层最后关键帧的 RTP 时间戳。
  - **`OnCapturedFrame()`**：将帧入队，超过 `kMaxPendingFrames(2)` 时丢弃最老的帧。
  - **`OnEncodedImage()`** 完整流程：
    1. 根据 RTP 时间戳从 `captured_frames_` 队列匹配对应的原始帧。
    2. 通过 `GetSpatialLayerId()` 获取层 ID。
    3. 检查是否为关键帧：若是，更新 `rtp_timestamp_of_last_key_frame`；若否且该层无上下文，则跳过（第一次见到非关键帧层时拒绝）。
    4. 关键帧时调整 sequence_index：若低 7 位非零则向上对齐到下一个 128 的倍数）。
    5. 检查 14 位溢出，溢出时重置为 0。
    6. 调用 `GetSampleCoordinatesForFrameIfFrameShouldBeSampled()`：判断是否应对该帧进行采样（关键帧或满足采样间隔条件）。
    7. 根据编码图像的 QP 值或编解码器类型获取 `CorruptionDetectionFilterSettings`。
    8. 调用 `GetSampleValuesForFrame()` 在原始帧的指定坐标处提取经过高斯滤波的采样值。
    9. 返回包含采样值的 `FrameInstrumentationData`。
- **`GetCorruptionFilterSettings()`**：优先使用编码器实现提供的 filter settings（来自 `EncodedImage` 的 `corruption_detection_filter_settings` 字段），若无则根据 QP 值使用通用设置。

## 学习扩展

- **Halton 序列间隔采样**：`GetSampleCoordinatesForFrameIfFrameShouldBeSampled()` 决定哪些帧需要被采样，通常关键帧一定采样，后续帧根据策略间隔采样。
- **kMaxPendingFrames = 2**：防止编码器丢弃帧导致的帧缓冲区耗尽，仅在短期保留未编码的原始帧。
- **QP 解析**：若编码图像未提供 QP 值，使用 `QpParser` 从编码比特流中解析 QP。QP 用于推断 `CorruptionDetectionFilterSettings`（如标准差和阈值）。

## 设计模式

**工厂方法模式（Factory Method）**：`Create()` 静态工厂方法创建具体实现。**生产者-消费者模式**：`OnCapturedFrame` 生产原始帧，`OnEncodedImage` 消费并与编码图像匹配，形成原始帧到检测数据的转换管线。**线程安全设计**：使用 `Mutex` 保护所有可变状态。
