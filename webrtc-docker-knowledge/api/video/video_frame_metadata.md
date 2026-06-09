# video_frame_metadata

## 概述

`VideoFrameMetadata` 是 WebRTC 中可插入流（Insertable Streams）API 暴露给 JavaScript 的 RTP 视频头部元数据子集。它将 RTP 视频头部中的关键信息（帧类型、尺寸、旋转、内容类型、帧 ID、空间/时间层索引、帧依赖关系、编解码器特定信息、SSRC/CSRC 等）封装为独立的数据类。

## 头文件接口 (.h)

- **`RTPVideoHeaderCodecSpecifics`**：使用 `std::variant<std::monostate, RTPVideoHeaderVP8, RTPVideoHeaderVP9, RTPVideoHeaderH264>` 表示编解码器特定信息，根据 `VideoCodecType` 确定哪个变体有效。
- **核心字段**：
  - `frame_type_`：帧类型（关键帧/差值帧/空帧）。
  - `width_` / `height_`：帧分辨率。
  - `rotation_`：旋转角度。
  - `content_type_`：内容类型（实时/屏幕共享）。
  - `frame_id_` / `spatial_index_` / `temporal_index_`：帧标识和层索引。
  - `frame_dependencies_`：帧依赖 ID 列表。
  - `decode_target_indications_`：解码目标指示。
  - `is_last_frame_in_picture_`：图像中最后一帧标志。
  - `simulcast_idx_`：Simulcast 层索引。
  - `codec_` / `codec_specifics_`：编解码器类型和特定信息。
  - `ssrc_` / `csrcs_`：RTP SSRC 和 CSRC 列表。
- **Getter/Setter 方法**：每个字段有对应的 Get/Set 方法。
- **运算符**：`operator==` 和 `operator!=`，逐字段比较。

## 实现文件 (.cc)

- 所有 Getter/Setter 方法都是直接的字段访问。
- `SetFrameDependencies()` 和 `SetDecodeTargetIndications()` 使用 `assign()` 将 `ArrayView` 数据拷贝到内部 `InlinedVector`。
- `operator==` 逐字段比较全部私有成员。

## 学习扩展

- **Insertable Streams API**：W3C WebRTC 扩展规范，允许 JavaScript 在编码前和解码后访问和修改视频帧数据。`VideoFrameMetadata` 是此 API 中 RTP 头部元数据的表示。
- **std::variant 的应用**：使用 C++17 `std::variant` 而非联合体或基类指针来表示编解码器特定信息，既类型安全又高效。
- **使用 `absl::InlinedVector`**：小向量优化，对于帧依赖（通常 < 5 个）和解码目标指示（通常 < 10 个）可避免堆分配。

## 设计模式

**数据传输对象（DTO）**：`VideoFrameMetadata` 是纯粹的数据载体，将 RTP 视频头部中的元数据子集导出为独立对象，用于跨 API 边界（C++/JavaScript）传输。`std::variant` 的使用体现了代数数据类型的思想。
