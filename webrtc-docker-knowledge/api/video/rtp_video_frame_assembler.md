# rtp_video_frame_assembler

## 概述

`RtpVideoFrameAssembler` 是 WebRTC 中 RTP 视频帧的核心组装器，接收网络层传来的 `RtpPacketReceived`，将其拼装为完整的 `EncodedFrame`。当一帧的所有 RTP 包都收到后，解析出比特流数据、分配帧 ID、确认所有帧依赖关系，输出完整的帧对象。该类实际上是一个外观（Facade），内部委托给 `Impl` 实现类完成实际工作。

## 头文件接口 (.h)

- **内嵌类 `AssembledFrame`**：封装已组装完成的帧，包含 RTP 序列号范围和 `EncodedFrame`。
- **`FrameVector`**：`absl::InlinedVector<AssembledFrame, 3>`，单次 InsertPacket 可能产生多个帧（乱序包到达时）。
- **`PayloadFormat`**：枚举支持的负载格式——kRaw、kH264、kVp8、kVp9、kAv1、kGeneric、kH265。
- **核心方法**：`InsertPacket(const RtpPacketReceived&)`，输入 RTP 包，输出组装完成的帧向量。
- **PIMPL 设计**：实现细节完全隐藏在 `Impl` 内部类中。

## 实现文件 (.cc)

- **`CreateDepacketizer()`**：根据 PayloadFormat 创建对应的 `VideoRtpDepacketizer` 实例。
- **`Impl` 内部类**：
  - 成员：`depacketizer_`（RTP 解包器）、`packet_buffer_`（PacketBuffer，视频包缓冲区）、`reference_finder_`（RtpFrameReferenceFinder，帧引用关系解析器）、`video_structure_`（帧依赖结构）、序列号解包器等。
  - **`InsertPacket()`** 流程：
    1. 空包（padding）处理：调用 `UpdateWithPadding()`，可能触发完成被 padding 填补的帧。
    2. 非空包：调用 depacketizer 的 `Parse()` 解析 RTP 负载。
    3. 解析 Dependency Descriptor 或 Generic Frame Descriptor 扩展头。
    4. 构建 PacketBuffer::Packet，插入 `packet_buffer_`。
    5. 调用 `AssembleFrames()` 组装完整帧，然后调用 `FindReferences()` 通过 reference_finder 获得可解码的帧。
  - **`AssembleFrames()`**：将 PacketBuffer 中同一个帧的多个包聚合，调用 depacketizer 的 `AssembleFrame()` 合并 payload，创建 `RtpFrameObject`。
  - **`FindReferences()`**：将组装好的帧交由 `RtpFrameReferenceFinder` 解析帧间依赖关系，返回已就绪可解码的帧。
  - **`ParseDependenciesDescriptorExtension()`**：解析 Dependency Descriptor RTP 扩展头，提取帧 ID、空间/时间层索引、依赖关系、chain diffs、解码目标指示等。收到新 key frame 时会更新 `video_structure_`。
  - **`ParseGenericDescriptorExtension()`**：解析 Generic Frame Descriptor RTP 扩展头，帧 ID 解码后提取依赖关系 diffs。
  - **`ClearOldData()`**：周期性地清理 PacketBuffer 和 reference_finder 中的旧数据，阈值 2000 个序列号。

## 学习扩展

- **Dependency Descriptor**：WebRTC 新一代帧依赖描述方案，在 `FrameDependencyStructure` 中定义编码模板，RTP 包通过模板 ID 引用依赖结构，大幅减少每包传输的依赖信息量。
- **RtpFrameReferenceFinder**：负责建立帧间的参考关系，输出帧依赖图，只在所有依赖帧就绪后才输出帧。
- 了解 VP8/VP9/AV1/H264/H265 的 RTP 打包规范对理解 depacketizer 的实现有帮助。

## 设计模式

**外观模式（Facade）**：`RtpVideoFrameAssembler` 对上层提供简单的 `InsertPacket()` 接口，内部隐藏 PacketBuffer、ReferenceFinder、Depacketizer 等复杂组件的协调。**PIMPL 模式（Pointer to Implementation）**：实现细节隐藏在 `Impl` 内部类中，对外部只暴露稳定的 API。
