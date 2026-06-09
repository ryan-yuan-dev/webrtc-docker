# video_frame

## 概述

`VideoFrame` 是 WebRTC 中未编码视频帧的核心类，承载了原始帧缓冲区（VideoFrameBuffer）和丰富的元数据信息。它贯穿从视频采集到编码前的整个视频管线，提供时间戳、旋转、颜色空间、更新区域、RTP 包信息、处理时间等全方位帧描述能力。推荐通过内部的 `Builder` 类构建 VideoFrame 实例。

## 头文件接口 (.h)

- **内部结构体**：
  - `UpdateRect`：描述帧的更新区域（增量更新），提供 `Union()`、`Intersect()`、`ScaleWithFrame()` 等操作。
  - `ProcessingTime`：帧处理时间，包含 `start` 和 `finish` 时间戳。
  - `RenderParameters`：渲染参数，包含低延迟渲染标志和最大合成延迟帧数。
- **`Builder` 嵌套类**：推荐的构建方式，提供链式调用的 API 设置所有字段，最后调用 `build()` 产生 `VideoFrame` 实例。
- **关键方法**：
  - `width()` / `height()` / `size()`：帧尺寸。
  - `id()`：帧唯一标识（发送端局部唯一）。
  - `timestamp_us()`：系统单调时钟时间戳。
  - `presentation_timestamp()`：呈现时间戳。
  - `reference_time()`：捕获参考时间（单调递增时钟）。
  - `rtp_timestamp()` / `ntp_time_ms()`：RTP 和 NTP 时间戳。
  - `rotation()`：视频旋转角度。
  - `color_space()`：颜色空间描述。
  - `render_parameters()`：渲染参数。
  - `video_frame_buffer()`：帧缓冲区对象（`scoped_refptr<VideoFrameBuffer>`）。
  - `is_texture()`：判断是否是纹理格式的帧。
  - `update_rect()`：更新区域矩形。
  - `packet_infos()`：RTP 包信息。
  - `processing_time()`：处理时间。
  - `is_repeat_frame()`：是否是重复帧（用于编码器稳定质量和变化帧率场景）。
- **弃用构造函数**：提供传统构造函数（直接传 buffer 等参数），但推荐使用 Builder。

## 实现文件 (.cc)

- **`UpdateRect`**：
  - `Union()`：取并集，生成包含两个 rect 的最小矩形。
  - `Intersect()`：取交集，生成重叠部分矩形。
  - `MakeEmptyUpdate()`：重置为 0 尺寸。
  - `ScaleWithFrame()`：核心缩放逻辑——先裁剪、后缩放、再对齐到 2x2 网格、最后扩展 2 像素以覆盖缩放伪影。
- **`Builder`**：构建方法 `build()` 会校验 `video_frame_buffer_` 非空，然后调用私有构造函数创建 `VideoFrame`。
- **私有构造函数**：接收 Builder 中的所有字段作为参数，支持移动和拷贝语义。
- **`video_frame_buffer()`**：返回非空保证。
- **`render_time_ms()`**：从 `timestamp_us()` 计算毫秒值。

## 学习扩展

- **UpdateRect** 是视频帧增量更新的关键机制，用于支持视频编码器的增量帧间预测优化。`ScaleWithFrame` 中特别的 2x2 网格对齐和 2 像素扩展设计考虑了色度子采样的边界效应。
- **is_repeat_frame**：当摄像头以可变帧率运行时，在无明显变化的帧间隔中插入重复帧，帮助编码器保持稳定的质量。
- **Builder 模式**是 WebRTC 中构造复杂对象的推荐方式，可以避免构造参数过多、顺序错误等问题。

## 设计模式

**建造者模式（Builder）**：`Builder` 内部类将复杂的 `VideoFrame` 对象构建过程与表示分离，支持链式调用和灵活的字段设置。**值对象（Value Object）**：`UpdateRect`、`ProcessingTime`、`RenderParameters` 作为值类型结构体，支持拷贝和比较。
