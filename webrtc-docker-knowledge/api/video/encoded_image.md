# encoded_image

## 概述

`EncodedImage` 是 WebRTC 中表示编码后视频帧图像的核心数据结构，承载编码后的比特流数据及其元数据。它配合 `EncodedImageBufferInterface` / `EncodedImageBuffer` 管理实际像素数据的内存，并提供丰富的元数据描述能力，包括时间戳、空间/时间层索引、颜色空间、播放延迟、PSNR、corruption detection 设置等。

## 头文件接口 (.h)

- **`EncodedImageBufferInterface`**：抽象接口，定义 `data()` 和 `size()`，继承 `RefCountInterface`，支持外部编码器托管的内存释放（如 Java 编码器的 `releaseOutputBuffer`）。
- **`EncodedImageBuffer`**：基于 `Buffer` 的具体实现，提供静态工厂方法 `Create()`，支持从已有数据构造和重新分配内存。
- **`EncodedImage`**（主类）：
  - **时间戳**：RTP 时间戳（90kHz）、捕获时间、NTP 时间、呈现时间戳。
  - **分层信息**：SimulcastIndex（模拟广播层）、SpatialIndex（空间层）、TemporalIndex（时间层）、`SpatialLayerFrameSize()`。
  - **元数据**：ColorSpace、PlayoutDelay、VideoFrameTrackingId、PacketInfos、RetransmissionAllowed。
  - **帧特征**：FrameType（关键帧/增量帧）、ContentType、Rotation、QP 量化参数、`at_target_quality`、`is_steady_state_refresh_frame`。
  - **计时结构 `Timing`**：包含编码开始/结束、打包完成、Pacer 出口、网络时间戳、接收时间戳等。
  - **PSNR**：可选的 Y/U/V 分量峰值信噪比。
- **公有成员变量**：`_encodedWidth`、`_encodedHeight`、`ntp_time_ms_`、`capture_time_ms_`、`_frameType`、`rotation_`、`content_type_`、`qp_`、`timing_`。

## 实现文件 (.cc)

- **`EncodedImageBuffer`**：使用 `rtc::Buffer` 管理内存，`Realloc()` 方法改变缓冲区大小。
- **`EncodedImage`** 默认构造和拷贝构造函数使用 `= default`。
- **`SetEncodeTime()`**：设置编码开始/结束时间到 `timing_` 结构中。
- **`CaptureTime()`**：根据 `capture_time_ms_` 返回 `Timestamp`，若无效则返回负无穷。
- **`SpatialLayerFrameSize()` / `SetSpatialLayerFrameSize()`**：通过 `std::map<int, size_t>` 存储每个空间层的帧大小，用于多层编码场景。

## 学习扩展

- **Simulcast vs SVC**：Simulcast 中每个层是独立编码的流，SpatialIndex 无意义；SVC 中空间层之间存在依赖关系。
- **PlayoutDelay** 的 `VideoPlayoutDelay` 结构体定义在 `video_timing.h` 中，最小/最大延迟用于接收端自适应播放。
- **corruption_detection_filter_settings**：编码器可提供自定义的 corruption detection 参数，用于接收端检测视频流中的质量问题。
- `kMaxSimulcastStreams` 和 `kMaxSpatialLayers` / `kMaxTemporalStreams` 限制见 `video_codec_constants.h`。

## 设计模式

**策略模式（Strategy）的就绪状态**：`EncodedImageBufferInterface` 抽象了像素数据的存储策略，让外部编码器可以提供自定义的内存管理方式（如 DirectBuffer、共享内存等）。
