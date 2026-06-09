# libaom_av1_encoder_factory

## 概述

`libaom_av1_encoder_factory` 是 WebRTC 为 AV1 编码器设计的新一代工厂接口实现。它基于 libaom 库（Google 的 AV1 参考实现）提供 AV1 实时编码能力。该模块同时使用了 WebRTC 最新的编码器抽象层——`VideoEncoderFactoryInterface` 和 `VideoEncoderInterface`，而不是传统的 `VideoEncoder` 接口。它实现了从 SVC（Scalable Video Coding）配置到 libaom APIs 的完整映射，支持多层（spatial + temporal）编码、CBR/CQP 码率控制模式和多种参考帧管理策略。

## 头文件接口 (.h)

**类 `LibaomAv1EncoderFactory`**（继承 `VideoEncoderFactoryInterface`）：
- `CodecName()`：返回 `"AV1"`。
- `ImplementationName()`：返回 `"Libaom"`。
- `CodecSpecifics()`：返回空映射。
- `GetEncoderCapabilities()`：返回编码器能力描述，包括预测约束、输入约束（64x36 ~ 3840x2160）、编码格式（I420/NV12）、帧类型支持和码率控制模式。
- `CreateEncoder(settings, encoder_specific_settings)`：创建并初始化 `LibaomAv1Encoder` 实例。

## 实现文件 (.cc)

**核心类 `LibaomAv1Encoder`**（继承 `VideoEncoderInterface`）：
- 封装 libaom 的 `aom_codec_ctx_t` 作为底层编码器句柄。
- 使用宏 `SET_OR_RETURN` 和 `SET_OR_RETURN_FALSE` 封装 libaom 控制参数的设置，简化错误处理。

**`InitEncode`** 初始化流程：
1. 验证 `encoder_specific_settings` 必须为空（不支持私有参数）。
2. 调用 `aom_codec_enc_config_default` 获取默认配置。
3. 配置编码参数：时基为 90kHz（RTP 标准）、禁用 key-frame 自动插入（`AOM_KF_DISABLED`）、单 pass 实时编码（`AOM_USAGE_REALTIME`）、零延迟（`g_lag_in_frames = 0`）。
4. 根据是否 CBR 模式配置缓冲区大小（`rc_buf_*`）。
5. 调用 `aom_codec_enc_init` 初始化编码器。
6. 通过 `SET_OR_RETURN_FALSE` 批量设置编码器控制参数——大量禁用不必要的编码工具（如 TPL 模型、OBMC、Warped Motion、Global Motion、Tx64、矩形分块等），启用适应实时场景的优化（Row MT、AQ mode 3、CDEF）。

**`Encode`** 编码流程：
1. 使用 `absl::Cleanup` 确保异常返回时回调所有未完成的 `EncodeComplete`。
2. 调用 `ValidateEncodeParams` 验证编码参数（帧设置、参考帧、空间时间 ID、QP 模式匹配等）。
3. 根据内容类型（屏幕共享 vs 实时视频）调整编码器设置（Tune Content、Palette）。
4. 计算总 CBR 目标码率。
5. 检测分辨率变化时动态调整线程数/瓦片数/Superblock 大小（通过 `GetThreadingTilesAndSuperblockSize`）。
6. 使用 `PrepareInputImage` 将 `VideoFrameBuffer`（I420/NV12）包装到 libaom 图像结构。
7. 配置 SVC 参数：调用 `GetSvcParams` 为每个空间/时间层配置码率和 QP。
8. 遍历 spatial layers 调用 `aom_codec_encode` 进行实际编码（即使某些层不需要编码，libaom 也要求调用）。
9. 通过 `aom_codec_get_cx_data` 获取编码后码流，调用 `GetBitstreamOutputBuffer` 和 `EncodeComplete` 回调。

**SVC 参考帧配置**（`GetSvcRefFrameConfig`）：
- 将用户指定的参考缓冲区映射到 libaom 的 LAST/GOLDEN/ALTREF 引用位置，按照优先级（0 -> 3 -> 6 -> 1/2/4/5）分配。
- 处理 start frame 和 delta frame 的不同参考帧需求。

**SVC 参数配置**（`GetSvcParams`）：
- 为 CBR 模式需要设置最高 temporal 层的码率（libaom 按所有 spatial 层的最高 temporal 层码率求和计算总码率）。
- 为 CQP 模式设置 `layer_target_bitrate = 1` 以确保层被 libaom 识别为活动状态，同时设置 QP 范围。

**线程和瓦片策略**（`GetThreadingTilesAndSuperblockSize`）：
- 根据分辨率分级决定线程数和瓦片数：1080p+ 用 8 线程 2x1 瓦片；360p+ 用 4 线程 1x1；180p+ 用 2 线程；以下用 1 线程。
- 960x540+ 且线程 > 4 时使用 64x64 Superblock，否则动态选择。

## 学习扩展

- 本文件使用了新的 `VideoEncoderFactoryInterface` / `VideoEncoderInterface` 抽象（区别于传统的 `VideoEncoder`），这是 WebRTC 编码器架构演进的方向，提供了更细粒度的 SVC 控制和帧级编码参数设置。
- libaom 在 RTC 模式下（`AOM_USAGE_REALTIME`）做了大量编码速度优化，本模块进一步禁用了几乎所有非必要的编码工具以换取编码速度。
- SVC 参考帧管理是 SVC 编码中最复杂的部分之一，需要精确控制每个 spatial/temporal 层何时更新哪个缓冲区、引用哪些缓冲区。
- `Effort Level`（-2 到 2）映射到 libaom 的 `cpu_used`（6 到 10），负值更小表示更低延迟（更快编码）。

## 设计模式

**工厂方法模式**：`LibaomAv1EncoderFactory` 作为工厂，`CreateEncoder` 方法创建并初始化编码器实例。

**适配器模式**：将 libaom 的 C 风格 API（`aom_codec_*`）适配到 WebRTC 的 C++ 接口（`VideoEncoderInterface`），处理内存管理、错误转换和参数映射。

**RAII**：使用 `aom_img_ptr`（unique_ptr 自定义删除器）管理 libaom 图像资源，确保异常安全。

**Cleanup 惯用法**：使用 `absl::Cleanup` 确保 `Encode` 方法在提前返回时正确完成所有帧编码状态的回调，避免悬挂回调。

**宏封装**：使用 `SET_OR_RETURN` / `SET_OR_RETURN_FALSE` 宏简化 libaom 控制参数设置的错误处理，减少重复代码。
