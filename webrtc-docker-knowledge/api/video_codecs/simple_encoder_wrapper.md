# simple_encoder_wrapper

## 概述

`SimpleEncoderWrapper` 是一个高层封装类，旨在简化新的 `VideoEncoderInterface` 的使用。它将编码器实例与 `ScalableVideoController`（SVC 结构控制器）结合，自动管理 SVC 层的帧配置、参考帧关系和编码参数设置。该类适合作为 Proof-of-Concept 或测试用途，提供了最简编码接口：只需提供帧缓冲区和 QP/fps 设置即可完成编码。

## 头文件接口 (.h)

**结构体 `EncodeResult`**：
- `oh_no`：编码是否失败。
- `bitstream_data`：编码后的码流数据。
- `frame_type`：帧类型。
- `generic_frame_info`：通用帧描述信息。
- `dependency_structure`：关键帧时的依赖结构描述。

**核心函数**：
- `SupportedWebrtcSvcModes(prediction_constraints)`：静态方法，根据编码器能力生成所有支持的 SVC 模式字符串列表。
- `Create(encoder, scalability_mode)`：静态工厂方法，创建 `SimpleEncoderWrapper` 实例。
- `SetEncodeQp(qp)`：设置编码 QP 值。
- `SetEncodeFps(fps)`：设置编码帧率。
- `Encode(frame_buffer, force_keyframe, callback)`：执行编码，结果通过回调异步返回。

## 实现文件 (.cc)

**`SupportedWebrtcSvcModes`**：
- 根据编码器的预测约束（最大空间/时间层数、参考帧数量、缩放因子等）生成所有合法的 SVC 模式字符串组合。
- 支持三种空间层间关系：`kS`（独立）、`kL`（预测）、`kKey`（仅关键帧预测）。
- 支持两种缩放比例：1/2 和 2/3。

**`Create`**：
- 调用 `ScalabilityModeStringToEnum` 将字符串解析为枚举。
- 调用 `CreateScalabilityStructure` 创建 SVC 控制器。
- 在构造函数中调用 `StreamConfig()` 获取层配置（缩放因子等）。

**`Encode`**：
1. 调用 SVC 控制器的 `NextFrameConfig(force_keyframe)` 获取当前帧的层配置。
2. 为每个层构建 `FrameEncodeSettings`：设置 CQP 模式、spatial/temporal ID、分辨率（根据缩放因子计算）、参考和更新缓冲区。
3. 如果没有参考缓冲区，标记为关键帧。
4. 创建 `FrameOut` 回调对象（继承 `FrameOutput`），实现 `GetBitstreamOutputBuffer` 和 `EncodeComplete`。
5. 调用编码器的 `Encode` 方法。
6. 更新时间戳（`presentation_timestamp_ += 1/fps`）。

## 学习扩展

- 该类展示了 WebRTC 新编码器接口（`VideoEncoderInterface`）的典型使用方式：利用 `ScalableVideoController` 生成层配置，再通过 `FrameEncodeSettings` 精确控制每一层的编码参数。
- SVC 控制器负责决定哪些缓冲区需要更新或引用，而 `SimpleEncoderWrapper` 负责将这些决策翻译为编码器能够理解的设置。
- 目前仅支持 CQP 模式（注释提到"应该只支持 CBR，但需要处理层分配"），这是简化实现的有意选择。

## 设计模式

**外观模式（Facade）**：`SimpleEncoderWrapper` 封装了 SVC 控制器 + 编码器接口 + 缓冲区管理的复杂性，对外提供最简编码接口。

**工厂方法**：`Create` 静态方法根据 scalability_mode 字符串选择合适的 SVC 结构实现。

**回调模式**：编码结果通过 `EncodeResultCallback` 异步返回，允许调用者在不阻塞的情况下获取编码结果。
