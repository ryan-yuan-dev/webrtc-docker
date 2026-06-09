# frame_instrumentation_evaluation

## 概述

`FrameInstrumentationEvaluation` 是 WebRTC 视频质量检测（Corruption Detection）系统的接收端评估组件。它接收发送端生成的 `FrameInstrumentationData` 和对应的已解码 `VideoFrame`，通过 Halton 帧采样器在接收帧相同位置重新采样，然后计算发送端采样值与接收端采样值的差异，最终输出一个 [0.0, 1.0] 范围的 corruption 概率分数。

## 头文件接口 (.h)

- **`CorruptionScoreObserver`**（接口）：接收 corruption 检测结果，`OnCorruptionScore(double corruption_score, VideoContentType content_type)`。
- **`FrameInstrumentationEvaluation`**（抽象类）：
  - `Create(CorruptionScoreObserver*)`：静态工厂方法。
  - `OnInstrumentedFrame(data, frame, frame_type)`：输入检测数据和帧，触发评估并回调 observer。
- **私有构造函数**：防止直接实例化。

## 实现文件 (.cc)

- **`FrameInstrumentationEvaluationImpl`**：
  - **构造函数**：初始化 `HaltonFrameSampler` 和 `CorruptionClassifier`（scale_factor=3）。
  - **`OnInstrumentedFrame()` 流程**：
    1. 若无采样值（sync 消息），静默忽略。
    2. 调用 `frame_sampler_.SetCurrentIndex(data.sequence_index())` 恢复采样位置。
    3. 调用 `frame_sampler_.GetSampleCoordinatesForFrame()` 获取采样坐标。
    4. 调用 `GetSampleValuesForFrame()` 从已知 `VideoFrame` 中提取采样值（像素数据经过高斯滤波）。
    5. 将发送端采样值（`data.sample_values()`）和本端采样值组合。
    6. 调用 `CorruptionClassifier::CalculateCorruptionProbability()` 计算 corruption 分数。
    7. 通过 `observer_->OnCorruptionScore()` 发送结果。
- **`ConvertSampleValuesToFilteredSamples()`**：将 double 数值数组与 `FilteredSample` 数组按相同位置合并，保留 plane 信息。

## 学习扩展

- **HaltonFrameSampler**：使用 Halton 低差异序列在帧中产生空间均匀的采样点，确保采样点不聚类，有效覆盖整个帧区域。
- **CorruptionClassifier**：比较发送端和接收端在同一采样位置的像素值差异，统计超过阈值的采样点比例，结合标准差和误差阈值输出概率分数。
- **scale_factor 参数**：滤波器中的 scale factor（此处为 3）用于高斯模糊的窗口大小。

## 设计模式

**工厂方法模式（Factory Method）**：`Create()` 静态工厂方法创建 `FrameInstrumentationEvaluationImpl` 实例。**观察者模式（Observer）**：`CorruptionScoreObserver` 观察并接收 corruption 检测结果，实现评估模块与消费模块的解耦。
