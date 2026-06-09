# color_space

## 概述

`ColorSpace` 类表示符合 ITU-T H.273 标准的颜色信息，涵盖视频帧的主原色、传输特性、矩阵系数、量化范围、色度采样位置以及 HDR 元数据。这是 WebRTC 中视频帧颜色空间描述的标准化表示，用于 VP9、VP8 和 H264 等编解码器的颜色配置传递。

## 头文件接口 (.h)

- **枚举类型**：
  - `PrimaryID`：主原色，对应 H.273 Table 2，如 kBT709、kBT2020 等。
  - `TransferID`：传输特性，对应 H.273 Table 3，如 kBT709、kSMPTEST2084（PQ）、kARIB_STD_B67（HLG）等。
  - `MatrixID`：矩阵系数，对应 H.273 Table 4，如 kRGB、kBT709、kBT2020_NCL、kBT2100_ICTCP 等。
  - `RangeID`：视频信号量化范围，kInvalid（无效）、kLimited（有限范围 16-235）、kFull（全范围 0-255）、kDerived（由矩阵/传输特性推导）。
  - `ChromaSiting`：色度采样位置，kUnspecified、kCollocated、kHalf。

- **构造函数**：提供两套构造方式——基础和完整版（含 ChromaSiting 和 HdrMetadata）。
- **访问器**：`primaries()`、`transfer()`、`matrix()`、`range()`、`chroma_siting_horizontal/vertical()`、`hdr_metadata()`、`AsString()`。
- **设置方法**：`set_*_from_uint8()` 系列方法，允许从 H.273 枚举整数值设置颜色参数，并进行合法性校验。
- **运算符**：`operator==` 和 `operator!=`，比较所有字段。

## 实现文件 (.cc)

- **编译期位掩码校验**：使用 `CreateEnumBitmask` 模板函数在编译期生成枚举值的位掩码，`SetFromUint8` 函数在运行时将 uint8 值转换为枚举类型并校验合法性。若枚举值 >= 64 会触发编译错误（`EnumMustBeLessThan64()`）。
- **`AsString()`**：使用 `SimpleStringBuilder` 构造人类可读的颜色空间描述字符串。
- **HDR 元数据**：`hdr_metadata_` 字段以 `std::optional<HdrMetadata>` 存储，构造时若传入非空指针则进行深拷贝。

## 学习扩展

- **H.273 标准**是视频信号颜色描述的国际标准，理解 Primary/Transfer/Matrix 的含义对 HDR 和广色域视频处理至关重要。
- VP9 支持完整的 ColorSpace 描述；VP8 只支持 BT.601；H264 使用 VUI（Video Usability Information）参数表示颜色信息。
- **PQ（SMPTE ST 2084）** 和 **HLG（ARIB STD-B67）** 是两种主流的 HDR 传输曲线。

## 设计模式

**值对象模式（Value Object）**：ColorSpace 是不可变的值对象（除 `set_hdr_metadata` 外通过构造函数初始化），支持拷贝和比较。编译期位掩码校验体现了一种**防错设计**，在编译早期捕获无效枚举值。
