# media_configuration

## 概述

`media_configuration` 模块定义了 PeerConnection 端到端测试中使用的媒体配置数据结构。包括视频配置（VideoConfig）、音频配置（AudioConfig）、屏幕共享配置（ScreenShareConfig）、仿真的选择性转发单元（EmulatedSFUConfig）等。

## 头文件接口 (.h)

### 核心配置结构

**`ScrollingParams`** — 屏幕共享滚动参数：
- `duration` — 滚动持续时间
- `source_width` / `source_height` — 源视频尺寸

**`ScreenShareConfig`** — 屏幕共享流属性：
- `slide_change_interval` — 幻灯片切换间隔
- `generate_slides` — 是否程序化生成幻灯片
- `scrolling_params` — 可选滚动参数
- `slides_yuv_file_names` — YUV 幻灯片文件列表

**`VideoSimulcastConfig`** — Simulcast/SVC 配置：
- `simulcast_streams_count` — Simulcast 流数或 SVC 层数

**`EmulatedSFUConfig`** — 仿真 SFU（选择性转发单元）配置：
- `target_layer_index` — 目标空间/Simulcast 层索引
- `target_temporal_index` — 目标时间层索引

**`VideoResolution`** — 视频分辨率：
- 支持普通分辨率（width, height, fps）和特殊规格（`kMaxFromSender`）。
- `IsRegular()` — 是否为普通分辨率。
- 重载 `==` / `!=`。

**`VideoDumpOptions`** — 视频转储选项：
- `output_directory` — 输出目录
- `sampling_modulo` — 采样间隔（每 N 帧转储一帧）
- `export_frame_ids` — 是否导出帧 ID
- `video_frame_writer_factory` — 帧写入器工厂函数（默认 Y4M 格式）
- `CreateInputDumpVideoFrameWriter()` / `CreateOutputDumpVideoFrameWriter()` — 创建输入/输出视频帧写入器

**`VideoConfig`** — 视频流配置：
- `width` / `height` / `fps`
- `stream_label` — 流标签（需唯一）
- `content_hint` — 内容提示（屏幕共享等）
- `simulcast_config` — Simulcast 配置
- `emulated_sfu_config` — 仿真 SFU 配置
- `encoding_params` — 编码参数
- `temporal_layers_count` — 时间层数
- `input_dump_options` / `output_dump_options` — 输入/输出转储选项
- `show_on_screen` — 是否在屏幕显示
- `sync_group` — 同步组
- `degradation_preference` — 降级偏好

**`AudioConfig`** — 音频配置：
- `stream_label`, `input_file_name`, `input_dump_file_name`, `output_dump_file_name`
- `audio_options`, `sampling_frequency_in_hz`, `sync_group`

**`VideoCodecConfig`** — 视频编解码器配置：
- `name` — 编解码器名称
- `required_params` — SDP 中必需的编解码器参数

**`VideoSubscription`** — 视频订阅配置：
- `SubscribeToPeer(peer_name, resolution)` — 订阅指定端
- `SubscribeToAllPeers(resolution)` — 订阅所有端
- `GetResolutionForPeer(peer_name)` — 获取指定端的订阅分辨率
- `GetSubscribedPeers()` — 获取已订阅端列表
- `GetMaxResolution()` — 计算所有视频配置中的最大分辨率

**`EchoEmulationConfig`** — 回声仿真配置：
- `echo_delay` — 回声路径延迟（默认 50ms）

## 实现文件 (.cc)

- `ScreenShareConfig` 和 `VideoSimulcastConfig` 构造函数检查参数合法性。
- `EmulatedSFUConfig` 验证空间/时间层索引非负。
- `VideoResolution` 的 `operator==` 特殊处理 Spec 模式：当 spec 非 `kNone` 且相同时，忽略其他字段。
- `VideoDumpOptions` 使用 `test::Y4mVideoFrameWriterImpl` 写入 Y4M 格式，可选择包装 `VideoFrameWithIdsWriter`。
- `VideoSubscription::GetMaxResolution()` 遍历所有输入分辨率，取各维度的最大值。
- 文件名生成格式：`<stream_label>_<width>x<height>_<fps>.y4m`。

## 学习扩展

- **SDP 编解码器协商**: WebRTC 使用 SDP 协议协商编解码器，`required_params` 用于精确匹配特定编解码器配置。
- **Simulcast / SVC**: Simulcast 发送多个独立编码的流，SVC 使用分层编码。
- **SFU (Selective Forwarding Unit)**: 在 SFU 架构中，服务器选择性地转发某些流层。
- **Y4M 格式**: YUV4MPEG2 容器格式，用于存储未压缩的视频帧序列。

## 设计模式

- **参数对象模式** — 各种 Config 配置结构体封装测试参数。
- **Builder 模式** — `VideoSubscription` 使用链式方法配置订阅。
- **工厂方法模式** — `VideoDumpOptions` 的 `video_frame_writer_factory` 作为工厂函数。
