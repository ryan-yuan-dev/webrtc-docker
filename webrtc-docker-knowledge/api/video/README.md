# WebRTC 视频模块 API 文档

## 概述

`api/video/` 定义了 WebRTC 视频处理流水线的数据结构、缓冲区和帧表示。视频处理是 WebRTC 中计算量最大的部分，高效的帧表示和颜色空间处理至关重要。

---

## 一、视频帧 — VideoFrame

### video_frame.cc
**路径**: `api/video/video_frame.cc`
**关键类**: `VideoFrame`, `VideoFrame::Builder`, `VideoFrame::UpdateRect`

`VideoFrame` 是 WebRTC 中表示一帧视频的核心类。它不仅包含像素数据，还包含丰富的元数据用于编码、传输和渲染。

**关键成员**:
| 成员 | 类型 | 说明 |
|------|------|------|
| `video_frame_buffer_` | `scoped_refptr<VideoFrameBuffer>` | 实际像素缓冲区（I420/NV12等） |
| `timestamp_us_` | `int64_t` | 微秒级时间戳 |
| `timestamp_rtp_` | `uint32_t` | RTP 时间戳（90kHz 时钟） |
| `ntp_time_ms_` | `int64_t` | NTP 时间戳（用于音视频同步） |
| `rotation_` | `VideoRotation` | 视频旋转（0/90/180/270） |
| `color_space_` | `std::optional<ColorSpace>` | 颜色空间信息 |
| `id_` | `uint16_t` | 帧 ID（用于编解码器参考帧追踪） |
| `update_rect_` | `std::optional<UpdateRect>` | 更新区域（脏矩形，用于部分更新/屏幕共享） |
| `packet_infos_` | `RtpPacketInfos` | 接收的 RTP 包信息集合 |

**Builder 模式**:
`VideoFrame::Builder` 提供流式 API 构建 VideoFrame。所有 setter 返回 `Builder&`，支持链式调用：
```cpp
auto frame = VideoFrame::Builder()
    .set_video_frame_buffer(buffer)
    .set_timestamp_us(capture_time_us)
    .set_rotation(kVideoRotation_0)
    .set_color_space(color_space)
    .build();
```

**`UpdateRect`** — 脏矩形 (Dirty Rectangle):
- `Union(other)` — 合并两个更新区域（取并集）
- `Intersect(other)` — 取两个更新区域的交集
- `ScaleWithFrame(...)` — 将更新区域从源帧坐标系映射到目标帧坐标系（处理裁剪和缩放）
- `IsEmpty()` — 是否为空（全帧更新时可能为空）
- `MakeEmptyUpdate()` — 标记为无更新

**UpdateRect 使用场景**: 屏幕共享/桌面采集时，只有变化的区域需要编码，UpdateRect 告诉编码器哪些区域发生了变化，大幅减少编码计算量。

### video_frame_buffer.cc
**路径**: `api/video/video_frame_buffer.cc`
**关键接口**: `VideoFrameBuffer`, `PlanarYuvBuffer`, `BiPlanarYuvBuffer`

`VideoFrameBuffer` 是所有视频帧缓冲区的抽象基类。

**继承体系**:
```
VideoFrameBuffer (抽象基类 - width, height, type)
├── I420BufferInterface    # YUV 4:2:0 三平面
│   └── I420Buffer         # 可写实现
├── I422BufferInterface    # YUV 4:2:2 三平面
├── I444BufferInterface    # YUV 4:4:4 三平面
├── I010BufferInterface    # YUV 4:2:0 10-bit
├── I210BufferInterface    # YUV 4:2:2 10-bit
├── I410BufferInterface    # YUV 4:4:4 10-bit
└── NV12BufferInterface    # YUV 4:2:0 双平面 (Y + UV交错)
```

**关键方法**:
- `ToI420()` — 转换为 I420 格式（最通用的 YUV 格式，所有编码器都支持）
- `type()` — 返回 `VideoFrameBuffer::Type` 枚举
- `GetI420()` / `GetI010()` — 类型安全的向下转型
- `CropAndScaleFrom()` / `ScaleFrom()` — 裁剪和缩放

### i420_buffer.cc (及其他 YUV 格式)
**路径**: `api/video/i420_buffer.cc`, `i422_buffer.cc`, `i444_buffer.cc`, `nv12_buffer.cc`, `i010_buffer.cc`, `i210_buffer.cc`, `i410_buffer.cc`

**I420 (YUV 4:2:0 8-bit)** — WebRTC 中最常用的格式：
```
Y 平面: 宽度×高度 (亮度, 全分辨率)
U 平面: (宽度/2)×(高度/2) (色度蓝, 水平/垂直均 1/2 子采样)
V 平面: (宽度/2)×(高度/2) (色度红, 水平/垂直均 1/2 子采样)
```
每像素 12 bits (1.5 bytes)

**内存对齐**: 使用 64 字节对齐 (`AlignedMalloc`) 以启用 SIMD 优化。

**关键操作** (通过 libyuv 实现):
- `Create(width, height)` — 工厂方法，使用 `make_ref_counted` 创建引用计数对象
- `Copy(source)` — 深拷贝另一个 I420 缓冲区
- `Rotate(source, rotation)` — 旋转 0/90/180/270 度
- `CropAndScaleFrom(src, ...)` — 裁剪并缩放（使用 libyuv::kFilterBox）
- `SetBlack(buffer)` — 填充为黑色 (Y=0, U=128, V=128)
- `InitializeData()` — 零填充整个缓冲区

**10-bit 格式 (I010/I210/I410)**:
- 每分量 10 bits，存储在 16-bit 中
- 用于 HDR (High Dynamic Range) 视频
- I010: 4:2:0 子采样
- I210: 4:2:2 子采样  
- I410: 4:4:4 子采样

**NV12 格式**:
- 双平面: Y 全分辨率 + UV 交错 (UVUVUV...)
- 某些硬件编码器原生支持此格式，避免 YUV 转换开销

---

## 二、颜色空间 — ColorSpace

### color_space.cc
**路径**: `api/video/color_space.cc`
**关键类**: `ColorSpace`

定义视频帧的颜色空间元数据（遵循 ITU-T H.273 / ISO/IEC 23091-2 标准）。

**四个核心属性**:
| 属性 | 枚举类型 | 示例值 |
|------|----------|--------|
| `primaries` | `PrimaryID` | BT.709 (HDTV), BT.2020 (UHD/HDR) |
| `transfer` | `TransferID` | BT.709 (SDR), SMPTE ST 2084 (HDR PQ), ARIB STD-B67 (HLG) |
| `matrix` | `MatrixID` | BT.709, BT.2020 (NCL/CL), BT.2100 ICtCp |
| `range` | `RangeID` | Limited (16-235), Full (0-255) |

**Chroma Siting**:
- `chroma_siting_horizontal_` / `chroma_siting_vertical_`
- 类型: `kUnspecified`, `kCollocated` (MPEG-2 风格), `kHalf` (MPEG-1/JPEG 风格)
- 决定色度采样点相对于亮度采样点的位置

**HDR 支持**:
- `kSMPTEST2084` 传输函数 = HDR10 PQ (Perceptual Quantizer)
- `kARIB_STD_B67` 传输函数 = HLG (Hybrid Log-Gamma)
- `kBT2020` 原色 = 广色域 (Rec. 2020)

**`set_*_from_uint8()` 系列**: 使用编译期 bitmask 技术进行安全的值域校验——通过 `CreateEnumBitmask` 模板在编译期生成所有合法枚举值的 bitmask，运行时 O(1) 验证。

**`AsString()`** — 序列化为可读字符串，用于日志输出。

### hdr_metadata.cc
**路径**: `api/video/hdr_metadata.cc`
**关键结构**: `HdrMetadata`

HDR 静态元数据（SMPTE ST 2086 母版显示参数 + MaxFALL/MaxCLL）。

---

## 三、编码帧

### encoded_frame.cc / encoded_image.cc
**路径**: `api/video/encoded_frame.cc`, `api/video/encoded_image.cc`
**关键类**: `EncodedFrame`, `EncodedImage`

编码后的视频帧表示。`EncodedImage` 是编码数据的容器，`EncodedFrame` 扩展了 RTP 相关信息。

**关键字段**:
- `_encodedWidth` / `_encodedHeight` — 编码分辨率
- `_frameType` — 帧类型 (VideoFrameType: kEmptyFrame, kVideoFrameKey, kVideoFrameDelta)
- `qp_` — 量化参数（质量指示）
- `SetRtpTimestamp()` / `RtpTimestamp()` — RTP 时间戳
- `SetSpatialIndex()` — 空间层索引 (SVC)
- `SetTemporalIndex()` — 时间层索引
- `SpatialLayerFrameSize()` — 空间层帧大小

### frame_buffer.cc
**路径**: `api/video/frame_buffer.cc`
**关键类**: 解码端帧缓冲管理

管理解码端帧缓冲，处理参考帧依赖、帧排序和渲染。

### rtp_video_frame_assembler.cc
**路径**: `api/video/rtp_video_frame_assembler.cc`
**关键类**: `RtpVideoFrameAssembler`

从 RTP 包组装完整视频帧。处理分包 (fragmentation)、聚合和排序。

### video_timing.cc
**路径**: `api/video/video_timing.cc`
**关键类**: 编码/解码时间戳处理

处理 `VideoTiming` 扩展头的编码和解码，记录帧在编码流水线中的各阶段时间戳。

---

## 四、码率与编码控制

### video_bitrate_allocation.cc / video_bitrate_allocator.cc
**路径**: `api/video/video_bitrate_allocation.cc`, `api/video/video_bitrate_allocator.cc`
**关键类**: `VideoBitrateAllocation`, `VideoBitrateAllocator`

**`VideoBitrateAllocation`** — 多空间层 / 多时间层的码率分配表。使用二维结构（空间层索引 × 时间层索引 → 码率 bps）。

**`VideoBitrateAllocator`** — 码率分配器接口。根据总目标码率和 `VideoBitrateAllocationParameters` 生成 `VideoBitrateAllocation`。不同编码器（VP8/VP9/H264）有不同的实现。

**分配策略** (由 `VideoBitrateAllocationParameters` 控制):
- `max_framerate` — 输入帧率上限
- `spatial_layers` — 空间层配置
- SVC 模式下，base layer 需保证最低码率，enhancement layers 分配剩余码率

### video_adaptation_counters.cc
**路径**: `api/video/video_adaptation_counters.cc`
**关键类**: `VideoAdaptationCounters`

跟踪视频自适应调整的计数器：分辨率降低次数、帧率降低次数。

### video_content_type.cc
**路径**: `api/video/video_content_type.cc`
**关键枚举**: `VideoContentType`

区分内容类型：`kRealtimeVideo` (摄像头) 和 `kScreenshare` (屏幕共享)。不同内容类型使用不同的编码策略。

### builtin_video_bitrate_allocator_factory.cc
**路径**: `api/video/builtin_video_bitrate_allocator_factory.cc`

创建内置码率分配器工厂。

---

## 五、Corruption Detection (损坏检测)

### corruption_detection/ 目录
**路径**: `api/video/corruption_detection/`

该目录实现帧损坏检测框架，用于识别和追踪视频传输过程中的数据损坏。

**关键类**:
- `FrameInstrumentationGenerator` — 生成帧校验数据
- `FrameInstrumentationData` / `FrameInstrumentationDataReader` — 帧检测数据的写/读
- `FrameInstrumentationEvaluation` — 评估损坏程度

---

## 学习扩展

### YUV 色彩空间

```
YUV 4:2:0 子采样示意图:

    X X X X    Y (亮度, 全分辨率)
    X X X X
    X X X X
    X X X X

    .   .      U (色度, 1/4 分辨率)
    .   .

    .   .      V (色度, 1/4 分辨率)
    .   .

总数据量 = W×H + 2×(W/2×H/2) = 1.5×W×H bytes
```

### 亮度与色度分离原理

人眼对亮度 (luma) 的敏感度远高于色度 (chroma)，因此 YUV 格式利用这一特性：
- **4:4:4**: 色度不子采样（每像素 3 分量，24 bits）
- **4:2:2**: 水平子采样 ×1/2（每像素 2 分量平均，16 bits）
- **4:2:0**: 水平和垂直均子采样 ×1/2（每像素 1.5 分量平均，12 bits）

### 视频帧处理流水线

```
采集 (Camera/Desktop)
  │
  ├─→ NV12/I420 原始帧
  │
  ▼
[VideoProcessing] (颜色空间转换、缩放)
  │
  ▼
[VideoEncoder] (VP8/VP9/H264/H265/AV1)
  │
  ├─→ EncodedImage
  │
  ▼
[RTP 打包与发送]
  │
  ... 网络传输 ...
  │
  ▼
[RTP 接收与解包]
  │
  ▼
[VideoDecoder]
  │
  ├─→ VideoFrame (可渲染帧)
  │
  ▼
[渲染]
```

### 关键设计模式

| 模式 | 出现位置 | 说明 |
|------|----------|------|
| **Builder** | `VideoFrame::Builder` | 流式构建不可变帧对象 |
| **Interface Segregation** | `VideoFrameBuffer` 继承体系 | I420/I422/I444/NV12 接口分离 |
| **Factory Method** | `I420Buffer::Create()` | 静态工厂 + 引用计数 |
| **Template Method** | `VideoFrameBuffer` | 基类定义骨架，子类实现 `ToI420()` |
| **Strategy** | `VideoBitrateAllocator` | 不同编码器的码率分配策略 |
| **Bridge** | `VideoFrameBufferInterface` ↔ libyuv | 跨平台优化的像素操作 |
| **Value Object** | `ColorSpace`, `HdrMetadata`, `UpdateRect` | 不可变数据对象 |
| **Flyweight** | `RefCounted` 视频缓冲区 | 引用计数共享，避免深拷贝 |

### HDR 视频支持

WebRTC 通过 `ColorSpace` + `HdrMetadata` 支持 HDR 视频传输：
- **HDR10**: BT.2020 原色 + SMPTE ST 2084 (PQ) 传输函数 + 静态元数据
- **HLG**: BT.2020 原色 + ARIB STD-B67 (HLG) 传输函数（与 SDR 兼容）
- 10-bit 缓冲区 (I010/I210/I410) 提供足够的精度
