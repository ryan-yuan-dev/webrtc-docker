# video_frame_buffer

## 概述

`VideoFrameBuffer` 是 WebRTC 中所有视频帧缓冲区的抽象基类，定义了帧缓冲区类型的枚举和核心接口。该文件还包括了按 YUV 采样格式分级的类层次结构：从 `PlanarYuvBuffer` 到 `PlanarYuv8Buffer`、`PlanarYuv16BBuffer`、`BiplanarYuvBuffer`，以及各自对应的具体接口子类（I420、I422、I444、I010、I210、I410、NV12 等）。`I420BufferInterface` 作为最通用的标准格式提供回退路径。

## 头文件接口 (.h)

- **`VideoFrameBuffer`**（抽象基类）：
  - **`Type` 枚举**：kNative, kI420, kI420A, kI422, kI444, kI010, kI210, kI410, kNV12。
  - **纯虚方法**：`type()`、`width()`、`height()`、`ToI420()`。
  - **GetXXX 方法**：`GetI420()`、`GetI420A()`、`GetI422()`、`GetI444()`、`GetI010()`、`GetI210()`、`GetI410()`、`GetNV12()`——仅当 `type()` 匹配时调用，否则 crash。
  - **缩放**：`CropAndScale()`（可被子类高效重写）和 `Scale()`。
  - **`GetMappedFrameBuffer()`**：kNative 帧可以返回主内存中的映射帧缓冲区。
  - **`storage_representation()`**：日志用字符串表示。
  - **`PrepareMappedBufferAsync()`**：异步准备映射帧缓冲区的钩子。
- **`PlanarYuvBuffer`**：平面 YUV 格式基类，添加 `ChromaWidth()`、`ChromaHeight()`、`Stride*()`。
- **`PlanarYuv8Buffer`**：8 位平面 YUV，添加 `DataY()`、`DataU()`、`DataV()`（uint8_t* 指针）。
- **`PlanarYuv16BBuffer`**：8-16 位平面 YUV，添加 `DataY()`、`DataU()`、`DataV()`（uint16_t* 指针）。
- **具体接口子类**：`I420BufferInterface`、`I420ABufferInterface`（带 Alpha 通道）、`I422BufferInterface`、`I444BufferInterface`、`I010BufferInterface`、`I210BufferInterface`、`I410BufferInterface`。
- **`BiplanarYuvBuffer` / `BiplanarYuv8Buffer`**：双平面 YUV 基类。
- **`NV12BufferInterface`**：NV12 格式的接口定义。
- **`CheckValidDimensions()`**：全局校验函数。

## 实现文件 (.cc)

- **`VideoFrameBuffer::CropAndScale()`**：默认实现通过 `ToI420()` 转换到 I420 后再进行裁切缩放。
- **`GetI420()` 默认实现**：返回 `nullptr`，由 `I420BufferInterface` 重写为返回 `this`。
- **`GetXXX()` 系列方法**：每个方法先 `RTC_CHECK(type() == Type::kXXX)` 然后 `static_cast`，确保类型安全。
- **接口默认行为**：
  - `I420BufferInterface`：`type()` 返回 `kI420`，`ChromaWidth/Height` 为 `(width+1)/2` 和 `(height+1)/2`。
  - `I422BufferInterface`：`ChromaWidth = (width+1)/2`，`ChromaHeight = height`。
  - `I444BufferInterface`：`ChromaWidth = width`，`ChromaHeight = height`。
  - `I010BufferInterface`：与 I420 相同的色度子采样（4:2:0），但像素为 16 位。
  - `I210BufferInterface`：与 I422 相同的色度子采样（4:2:2），16 位。
  - `I410BufferInterface`：与 I444 相同的色度子采样（4:4:4），16 位。
  - `NV12BufferInterface`：ChromaWidth = `(width+1)/2`，ChromaHeight = `(height+1)/2`。
- **`I422/I444/NV12BufferInterface::CropAndScale()`**：直接通过具体 Buffer 类（`I422Buffer`、`I444Buffer`、`NV12Buffer`）进行高效的格式内缩放到目标尺寸。
- **`VideoFrameBufferTypeToString()`**：Type 枚举的字符串化函数。
- **`CheckValidDimensions()`**：确保 width > 0、height > 0、stride_y >= width、stride_u > 0、stride_v > 0。

## 学习扩展

- **类层次设计目的**：以明确继承关系区分不同位深度（8-bit vs 16-bit）和不同布局（平面 vs 双平面），为视频处理管线提供编译期类型安全性。
- **ToI420() 是全局标准接口**：所有格式都必须能转换为 I420，这是 WebRTC 内部引擎的统一处理保证。即使 kNative 类型也需要实现此方法。
- **ChromaWidth / ChromaHeight**：取决于色度子采样格式（4:2:0、4:2:2、4:4:4），理解这些对正确操作 YUV 数据至关重要。

## 设计模式

**抽象工厂（Abstract Factory）接口**：`VideoFrameBuffer` 作为工厂层级中的产品基类，具体的 Buffer 实现类（如 `I420Buffer`）继承自对应的接口。**策略模式（Strategy）**：不同的 `CropAndScale` 实现允许子类提供更高效的格式内缩放策略。
